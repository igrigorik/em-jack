module EMJack
  module Handler
    class Buried
      RESPONSE = /^BURIED(\s+(\d+))?\r\n/

      def self.handles?(response)
        response =~ RESPONSE
      end

      def self.handle(deferrable, response, body, conn=nil)
        return false unless response =~ RESPONSE

        # if there is an id this is the response of a put command
        # otherwise, it's either the result of a BURY command or
        # a release command. I'm assuming the latter 2 are success
        # and the first is a failure
        id = $2
        if id.nil?
          deferrable.succeed
        else
          deferrable.fail(:buried, id.to_i)
        end
        true
      end
      
      EMJack::Connection.register_handler(EMJack::Handler::Buried)
    end
  end
end
