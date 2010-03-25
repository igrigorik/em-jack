module EMJack
  module Handler
    class Errors
      RESPONSE = /^(OUT_OF_MEMORY|INTERNAL_ERROR|DRAINING|BAD_FORMAT|UNKNOWN_COMMAND|EXPECTED_CRLF|JOB_TOO_BIG|DEADLINE_SOON|TIMED_OUT|NOT_FOUND)\r\n/i

      def self.handles?(response)
        response =~ RESPONSE
      end

      def self.handle(deferrable, response, body, conn=nil)
        return false unless response =~ RESPONSE
        deferrable.fail($1.downcase.to_sym)
        true
      end

      EMJack::Connection.register_handler(EMJack::Handler::Errors)
    end
  end
end