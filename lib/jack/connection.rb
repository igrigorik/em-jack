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
      message = @data + data
      @data = ""
      
      case(message)
      when /^OUT_OF_MEMORY\r\n/ then
        df = @deferrables.shift
        df.fail(:out_of_memory)
        
      when /^INTERNAL_ERROR\r\n/ then
        df = @deferrables.shift
        df.fail(:internal_error)
        
      when /^DRAINING\r\n/ then
        df = @deferrables.shift
        df.fail(:draining)
        
      when /^BAD_FORMAT\r\n/ then
        df = @deferrables.shift
        df.fail(:bad_format)
        
      when /^UNKNOWN_COMMAND\r\n/ then
        df = @deferrables.shift
        df.fail(:unknown_command)
        
      when /^INSERTED\s+(\d+)\r\n/ then
        df = @deferrables.shift
        df.succeed($1.to_i)
        
      when /^BURIED\s+(\d+)\r\n/ then
        df = @deferrables.shift
        df.fail(:buried, $i.to_i)
        
      when /^EXPECTED_CRLF\r\n/ then
        df = @deferrables.shift
        df.fail(:expected_crlf)
        
      when /^JOB_TOO_BIG\r\n/ then
        df = @deferrables.shift
        df.fail(:job_too_big)
      
      when /^USING\s+(.*)\r\n/ then
        df = @deferrables.shift
        df.succeed($1)
        
      when /^RESERVED\s+(\d+)\s+(\d+)\r\n(.*)\r\n/ then
        df = @deferrables.shift
        job = Jack::Job.new(self, $1, $3, $2)
        df.succeed(job)

      when /^DEADLINE_SOON\r\n/ then
        df = @deferrables.shift
        df.fail(:deadline_soon)
        
      when /^TIMED_OUT\r\n/ then
        df = @deferrables.shift
        df.fail(:timed_out)
        
      when /^DELETED\s+(\d+)\r\n/ then
        df = @deferrables.shift
        df.succeed($1.to_i)
        
      when /^NOT_FOUND\r\n/ then
        df = @deferrables.shift
        df.fail(:not_found)
      
      when /^WATCHING\s+(.*)\r\n/ then
        df = @deferrables.shift
        df.succeed($1)

      else
        @data = message
      end
    end
  end  
end
