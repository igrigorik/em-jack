module EMJack
  module Handler
    class Buried
      RESPONSE = /^BURIED\s+(\d+)\r\n/

      def self.handles?(response)
        response =~ RESPONSE
      end

      def self.handle(deferrable, response, body, conn=nil)
        return false unless response =~ RESPONSE

        deferrable.fail(:buried, $1.to_i)
        true
      end
      
      EMJack::Connection.register_handler(EMJack::Handler::Buried)
    end
  end
end
