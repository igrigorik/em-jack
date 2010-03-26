require 'eventmachine'

module EMJack
  class BeanstalkConnection < EM::Connection
    attr_accessor :client

    def connection_completed
      @client.connected
    end

    def receive_data(data)
      @client.received(data)
    end

    def send(command, *args)
      cmd = command.to_s
      cmd << " #{args.join(" ")}" unless args.length == 0
      cmd << "\r\n"
      send_data(cmd)
    end

    def send_with_data(command, data, *args)
      send_data("#{command.to_s} #{args.join(" ")}\r\n#{data}\r\n")
    end

    def unbind
      @client.disconnected
    end
  end
end