module EMJack
  module Handler
    class Inserted
      RESPONSE = /^INSERTED\s+(\d+)\r\n/

      def self.handles?(response)
        response =~ RESPONSE
      end

      def self.handle(deferrable, response, body, conn=nil)
        return false unless response =~ RESPONSE

        deferrable.succeed($1.to_i)
        true
      end

      EMJack::Connection.register_handler(EMJack::Handler::Inserted)
    end
  end
end