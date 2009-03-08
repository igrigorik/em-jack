require 'eventmachine'

module Jack
  class BeanstalkConnection < EM::Connection
    attr_accessor :client
    
    def receive_data(data)
      @client.received(data)
    end
    
    def send(command, *args)
      cmd = command.to_s
      cmd << " #{args.join(" ")}" unless args.length == 0
      cmd << "\r\n"
            
      puts "Sending: #{cmd}"
      send_data(cmd)
    end
    
    def send_with_data(command, data, *args)
      cmd = "#{command.to_s} #{args.join(" ")}\r\n#{data}\r\n"
      
      puts "Sending: #{cmd}"
      send_data(cmd)
    end
    
    def unbind
      puts "Disconnected"
    end
  end
  
  class Connection
    attr_accessor :host, :port
    
    def initialize(opts = {})
      @host = opts[:host] || 'localhost'
      @port = opts[:port] || 11300
      @tube = opts[:tube]
      
      @used_tube = 'default'
      @watched_tubes = ['default']
      
      @data = ""
      @in_reserve = false
      @deferrables = []
      
      @conn = EM::connect(host, port, Jack::BeanstalkConnection) do |conn|
        conn.client = self
      end
      
      unless @tube.nil?
        use(@tube)
        watch(@tube)
      end
    end
    
    def use(tube)
      return if @used_tube == tube
      @used_tube = tube
      @conn.send(:use, tube)
      add_deferrable
    end
    
    def watch(tube)
      return if @watched_tubes.include?(tube)
      @watched_tubes.push(tube)
      @conn.send(:watch, tube)
      add_deferrable
    end
    
    def reserve
      @conn.send(:reserve)
      add_deferrable
    end
    
    def delete(job)
      return if job.nil?
      @conn.send(:delete, job.jobid)
      add_deferrable
    end
    
    def put(msg, opts = {})
      pri = (opts[:priority] || 65536).to_i
      if pri< 0
         pri = 65536
      elsif pri > (2 ** 32)
        pri = 2 ** 32
      end
      
      delay = (opts[:delay] || 0).to_i
      delay = 0 if delay < 0
      
      ttr = (opts[:ttr] || 300).to_i
      ttr = 300 if ttr < 0
      
      m = msg.to_s
      
      @conn.send_with_data(:put, m, pri, delay, ttr, m.length)
      add_deferrable
    end
  
    def add_deferrable
      df = EM::DefaultDeferrable.new
      df.errback { |err| puts "ERROR: #{err}" }
      
      @deferrables.push(df)
      df
    end
  
    def received(data)
      @data << data

      until @data.empty?
        handled = false
        %w(out_of_memory internal_error draining bad_format 
           unknown_command expected_crlf job_too_big deadline_soon
           timed_out not_found).each do |cmd|
          next unless @data =~ /^#{cmd}\r\n/i
          df = @deferrables.shift
          df.fail(cmd.to_sym)

          @data = @data[(cmd.length + 2)..-1]
          handled = true
          break
        end
        next if handled

        case (@data)
        when /^DELETED\r\n/i then
          df = @deferrables.shift
          df.succeed

        when /^INSERTED\s+(\d+)\r\n/ then
          df = @deferrables.shift
          df.succeed($1.to_i)

        when /^BURIED\s+(\d+)\r\n/ then
          df = @deferrables.shift
          df.fail(:buried, $i.to_i)

        when /^USING\s+(.*)\r\n/ then
          df = @deferrables.shift
          df.succeed($1)

        when /^WATCHING\s+(\d+)\r\n/ then
          df = @deferrables.shift
          df.succeed($1)

        when /^RESERVED\s+(\d+)\s+(\d+)\r\n/ then
          id = $1.to_i
          bytes = $2.to_i
          
          rem = @data[(@data.index(/\r\n/) + 2)..-1]
          break if rem.length < bytes

          @data = rem
          body = @data[0..(bytes - 1)]
          @data = @data[(bytes + 2)..-1]
          
          df = @deferrables.shift
          job = Jack::Job.new(self, id, body)
          df.succeed(job)
          next
          
        else
          break
        end

        @data = @data[(@data.index(/\r\n/) + 2)..-1]
        next
      end
    end
  end  
end
