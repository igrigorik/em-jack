module EMJack
  module Handler
    class Deleted
      RESPONSE = /^DELETED\r\n/

      def self.handles?(response)
        response =~ RESPONSE
      end

      def self.handle(deferrable, response, body)
        return false unless response =~ RESPONSE

        deferrable.succeed
        true
      end

      EMJack::Connection.register_handler(EMJack::Handler::Deleted)
    end
  end
end