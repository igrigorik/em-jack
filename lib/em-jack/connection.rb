require 'eventmachine'
require 'yaml'

module EMJack
  class Connection
    include EM::Deferrable

    RETRY_COUNT = 5

    @@handlers = []

    attr_accessor :host, :port

    def self.register_handler(handler)
      @@handlers ||= []
      @@handlers << handler
    end

    def self.handlers
      @@handlers
    end

    def initialize(opts = {})
      @host = opts[:host] || 'localhost'
      @port = opts[:port] || 11300
      @tube = opts[:tube]

      reset_tube_state

      @data = ""
      @retries = 0
      @in_reserve = false
      @fiberized = false

      @conn = EM::connect(host, port, EMJack::BeanstalkConnection) do |conn|
        conn.client = self
      end

      unless @tube.nil?
        use(@tube)
        watch(@tube)
      end
    end

    def reset_tube_state
      prev_used = @used_tube
      prev_watched = @watched_tubes.dup if @watched_tubes

      @used_tube = 'default'
      @watched_tubes = ['default']
      @deferrables = []

      return [prev_used, prev_watched]
    end

    def fiber!
      @fiberized = true

      eigen = (class << self; self; end)
      eigen.instance_eval do
        %w(use reserve ignore watch peek stats list delete touch bury kick pause release put).each do |meth|
          alias_method :"a#{meth}", meth.to_sym
          define_method(meth.to_sym) do |*args|
            fib = Fiber.current
            ameth = :"a#{meth}"
            proc = lambda { |*result| fib.resume(*result) }
            send(ameth, *args, &proc)
            Fiber.yield
          end
        end
      end
    end

    def use(tube, &blk)
      return if @used_tube == tube

      callback {
        @used_tube = tube
        @conn.send(:use, tube)
      }

      add_deferrable(&blk)
    end

    def watch(tube, &blk)
      return if @watched_tubes.include?(tube)

      callback { @conn.send(:watch, tube) }

      df = add_deferrable(&blk)
      df.callback { @watched_tubes.push(tube) }
      df
    end

    def ignore(tube, &blk)
      return unless @watched_tubes.include?(tube)

      callback { @conn.send(:ignore, tube) }

      df = add_deferrable(&blk)
      df.callback { @watched_tubes.delete(tube) }
      df
    end

    def reserve(timeout = nil, &blk)
      callback {
        if timeout
          @conn.send(:'reserve-with-timeout', timeout)
        else
          @conn.send(:reserve)
        end
      }

      add_deferrable(&blk)
    end

    def peek(type = nil, &blk)
      callback {
        case(type.to_s)
        when /^\d+$/ then @conn.send(:peek, type)
        when "ready" then @conn.send(:'peek-ready')
        when "delayed" then @conn.send(:'peek-delayed')
        when "buried" then @conn.send(:'peek-buried')
        else raise EMJack::InvalidCommand.new
        end
      }

      add_deferrable(&blk)
    end

    def stats(type = nil, val = nil, &blk)
      callback {
        case(type)
        when nil then @conn.send(:stats)
        when :tube then @conn.send(:'stats-tube', val)
        when :job then @conn.send(:'stats-job', val.jobid)
        else raise EMJack::InvalidCommand.new
        end
      }

      add_deferrable(&blk)
    end

    def list(type = nil, &blk)
      callback {
        case(type)
        when nil then @conn.send(:'list-tubes')
        when :used then @conn.send(:'list-tube-used')
        when :watched then @conn.send(:'list-tubes-watched')
        else raise EMJack::InvalidCommand.new
        end
      }
      add_deferrable(&blk)
    end

    def delete(job, &blk)
      return if job.nil?

      callback { @conn.send(:delete, job.jobid) }

      add_deferrable(&blk)
    end

    def touch(job, &blk)
      return if job.nil?

      callback { @conn.send(:touch, job.jobid) }

      add_deferrable(&blk)
    end

    def bury(job, pri, &blk)
      callback { @conn.send(:bury, job.jobid, pri) }

      add_deferrable(&blk)
    end

    def kick(count = 1, &blk)
      callback { @conn.send(:kick, count) }

      add_deferrable(&blk)
    end

    def pause(tube, delay, &blk)
      callback { @conn.send(:'pause-tube', delay) }

      add_deferrable(&blk)
    end

    def release(job, opts = {}, &blk)
      return if job.nil?

      pri = (opts[:priority] || 65536).to_i
      delay = (opts[:delay] || 0).to_i

      callback { @conn.send(:release, job.jobid, pri, delay) }

      add_deferrable(&blk)
    end

    def put(msg, opts = nil, &blk)
      opts = {} if opts.nil?

      pri = (opts[:priority] || 65536).to_i
      pri = 65536 if pri< 0
      pri = 2 ** 32 if pri > (2 ** 32)

      delay = (opts[:delay] || 0).to_i
      delay = 0 if delay < 0

      ttr = (opts[:ttr] || 300).to_i
      ttr = 300 if ttr < 0

      m = msg.to_s

      callback { @conn.send_with_data(:put, m, pri, delay, ttr, m.bytesize) }

      add_deferrable(&blk)
    end

    def each_job(timeout = nil, &blk)
      if (@fiberized)
        work = Proc.new do
          Fiber.new do
            job = reserve(timeout)
            blk.call(job)
          end.resume
          EM.next_tick { work.call }          
        end
      else
        work = Proc.new do
          r = reserve(timeout)
          r.callback do |job|
            blk.call(job)
            EM.next_tick { work.call }
          end
          r.errback do
            EM.next_tick { work.call }
          end
        end
      end      
      work.call
    end

    def connected
      @reconnect_proc = nil
      @retries = 0
      succeed
      @connected_callback.call if @connected_callback
    end

    def disconnected
      d = @deferrables.dup

      ## if reconnecting, need to fail ourself to remove any callbacks
      fail

      set_deferred_status(nil)
      d.each { |df| df.fail(:disconnected) }

      if @retries >= RETRY_COUNT
        if @disconnected_callback
          @disconnected_callback.call
        else
          raise EMJack::Disconnected
        end
      end

      prev_used, prev_watched = reset_tube_state
      unless @reconnect_proc
        recon = Proc.new { reconnect(prev_used, prev_watched) }
        if @fiberized
          @reconnect_proc = Proc.new { Fiber.new { recon.call }.resume }
        else
          @reconnect_proc = recon
        end
      end

      @retries += 1
      EM.add_timer(5) { @reconnect_proc.call }
    end

    def reconnect(prev_used, prev_watched)
      @conn.reconnect(@host, @port)

      use(prev_used) if prev_used

      [prev_watched].flatten.compact.each do |tube|
        @fiberized ? awatch(tube) : watch(tube)
      end
    end

    def reconnect!
      @retries = 0

      prev_used, prev_watched = reset_tube_state
      EM.next_tick { reconnect(prev_used, prev_watched) }
    end

    def add_deferrable(&blk)
      df = EM::DefaultDeferrable.new
      if @error_callback
        df.errback { |err| @error_callback.call(err) }
      end

      df.callback &blk if block_given?

      @deferrables.push(df)
      df
    end

    def on_error(&blk)
      @error_callback = blk
    end

    def on_disconnect(&blk)
      @disconnected_callback = blk
    end

    def on_connect(&blk)
      @connected_callback = blk
    end

    def received(data)
      @data << data

      until @data.empty?
        idx = @data.index(/\r\n/)
        break if idx.nil?

        first = @data[0..(idx + 1)]
        df = @deferrables.shift
        handled, skip = false, false
        EMJack::Connection.handlers.each do |h|
          handles, bytes = h.handles?(first)

          next unless handles
          bytes = bytes.to_i

          if bytes > 0
            # if this handler requires us to receive a body make sure we can get
            # the full length of body. If not, we'll go around and wait for more
            # data to be received
            body, @data = extract_body!(bytes, @data) unless bytes <= 0
            break if body.nil?
          else
            @data = @data[(@data.index(/\r\n/) + 2)..-1]
          end

          handled = h.handle(df, first, body, self)
          break if handled
        end

        @deferrables.unshift(df) unless handled

        # not handled means there wasn't enough data to process a complete response
        break unless handled
        next unless @data.index(/\r\n/)

        @data = "" if @data.nil?
      end
    end

    def extract_body!(bytes, data)
      rem = data[(data.index(/\r\n/) + 2)..-1]
      return [nil, data] if rem.bytesize < bytes

      body = rem[0..(bytes - 1)]
      data = rem[(bytes + 2)..-1]
      data = "" if data.nil?

      [body, data]
    end
  end
end
