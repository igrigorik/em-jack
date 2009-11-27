require 'eventmachine'
require 'yaml'

module EMJack
  class Connection
    RETRY_COUNT = 5
 
    attr_accessor :host, :port
    
    def initialize(opts = {})
      @host = opts[:host] || 'localhost'
      @port = opts[:port] || 11300
      @tube = opts[:tube]
      
      @used_tube = 'default'
      @watched_tubes = ['default']
      
      @data = ""
      @retries = 0
      @in_reserve = false
      @deferrables = []
      
      @conn = EM::connect(host, port, EMJack::BeanstalkConnection) do |conn|
        conn.client = self
      end
      
      unless @tube.nil?
        use(@tube)
        watch(@tube)
      end
    end
    
    def use(tube, &blk)
      return if @used_tube == tube
      @used_tube = tube
      @conn.send(:use, tube)
      add_deferrable(&blk)
    end
    
    def watch(tube, &blk)
      return if @watched_tubes.include?(tube)
      @conn.send(:watch, tube)
      df = add_deferrable(&blk)
      df.callback { @watched_tubes.push(tube) }
      df
    end
    
    def ignore(tube, &blk)
      return unless @watched_tubes.include?(tube)
      @conn.send(:ignore, tube)
      df = add_deferrable(&blk)
      df.callback { @watched_tubes.delete(tube) }
      df
    end

    def reserve(timeout = nil, &blk)
      if timeout
        @conn.send(:'reserve-with-timeout', timeout)
      else
        @conn.send(:reserve)
      end
      add_deferrable(&blk)
    end

    def each_job(timeout = nil, &blk)
      work = Proc.new do
        r = reserve(timeout)
        r.callback do |job|
          blk.call(job)

          EM.next_tick { work.call }
        end
      end
      work.call
    end

    def stats(type = nil, val = nil, &blk)
      case(type)
      when nil then @conn.send(:stats)
      when :tube then @conn.send(:'stats-tube', val)
      when :job then @conn.send(:'stats-job', val.jobid)
      else raise EMJack::InvalidCommand.new
      end
      add_deferrable(&blk)
    end

    def list(type = nil, &blk)
      case(type)
      when nil then @conn.send(:'list-tubes')
      when :used then @conn.send(:'list-tube-used')
      when :watched then @conn.send(:'list-tubes-watched')
      else raise EMJack::InvalidCommand.new
      end
      add_deferrable(&blk)
    end

    def delete(job, &blk)
      return if job.nil?
      @conn.send(:delete, job.jobid)
      add_deferrable(&blk)
    end
    
    def release(job, &blk)
      return if job.nil?
      @conn.send(:release, job.jobid, 0, 0)
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
      
      @conn.send_with_data(:put, m, pri, delay, ttr, m.length)
      add_deferrable(&blk)
    end
  
    def connected
      @retries = 0
    end

    def disconnected
      # XXX I think I need to run out the deferrables as failed here
      # since the connection was dropped

      raise EMJack::Disconnected if @retries >= RETRY_COUNT
      @retries += 1
      EM.add_timer(1) { @conn.reconnect(@host, @port) }
    end

    def add_deferrable(&blk)
      df = EM::DefaultDeferrable.new
      df.errback do |err|
        if @error_callback
          @error_callback.call(err)
        else
          puts "ERROR: #{err}"
        end
      end
      
      df.callback &blk if block_given?

      @deferrables.push(df)
      df
    end
  
    def on_error(&blk)
      @error_callback = blk
    end
  
    def received(data)
      @data << data

      until @data.empty?
        idx = @data.index(/\r\n/)
        break if idx.nil?

        first = @data[0..(idx + 1)]

        handled = false
        %w(OUT_OF_MEMORY INTERNAL_ERROR DRAINING BAD_FORMAT
           UNKNOWN_COMMAND EXPECTED_CRLF JOB_TOO_BIG DEADLINE_SOON
           TIMED_OUT NOT_FOUND).each do |cmd|
          next unless first =~ /^#{cmd}\r\n/i
          df = @deferrables.shift
          df.fail(cmd.downcase.to_sym)

          @data = @data[(cmd.length + 2)..-1]
          handled = true
          break
        end
        next if handled

        case (first)
        when /^DELETED\r\n/ then
          df = @deferrables.shift
          df.succeed

        when /^INSERTED\s+(\d+)\r\n/ then
          df = @deferrables.shift
          df.succeed($1.to_i)

        when /^RELEASED\r\n/ then
          df = @deferrables.shift
          df.succeed

        when /^BURIED\s+(\d+)\r\n/ then
          df = @deferrables.shift
          df.fail(:buried, $1.to_i)

        when /^USING\s+(.*)\r\n/ then
          df = @deferrables.shift
          df.succeed($1)

        when /^WATCHING\s+(\d+)\r\n/ then
          df = @deferrables.shift
          df.succeed($1.to_i)

        when /^NOT_IGNORED\r\n/ then
          df = @deferrables.shift
          df.fail("Can't ignore only watched tube")

        when /^OK\s+(\d+)\r\n/ then
          bytes = $1.to_i

          body, @data = extract_body(bytes, @data)
          break if body.nil?

          df = @deferrables.shift
          df.succeed(YAML.load(body))
          next

        when /^RESERVED\s+(\d+)\s+(\d+)\r\n/ then
          id = $1.to_i
          bytes = $2.to_i

          body, @data = extract_body(bytes, @data)
          break if body.nil?

          df = @deferrables.shift
          job = EMJack::Job.new(self, id, body)
          df.succeed(job)
          next
          
        else
          break
        end

        @data = @data[(@data.index(/\r\n/) + 2)..-1]
        @data = "" if @data.nil?
      end
    end

    def extract_body(bytes, data)
      rem = data[(data.index(/\r\n/) + 2)..-1]
      return [nil, data] if rem.length < bytes

      body = rem[0..(bytes - 1)]
      data = rem[(bytes + 2)..-1]
      data = "" if data.nil?

      [body, data]
    end
  end  
end
