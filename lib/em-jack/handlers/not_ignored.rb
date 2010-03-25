module EMJack
  module Handler
    class NotIgnored
      RESPONSE = /^NOT_IGNORED\r\n/

      def self.handles?(response)
        response =~ RESPONSE
      end

      def self.handle(deferrable, response, body, conn=nil)
        return false unless response =~ RESPONSE

        deferrable.fail("Can't ignore only watched tube")
        true
      end

      EMJack::Connection.register_handler(EMJack::Handler::NotIgnored)
    end
  end
end
