module Maple::MapleTA
  module Errors
    class InvalidResponseError < MapleTAError
      attr_reader :response

      def initialize(response, msg=nil)
        @response = response
        super(msg.nil? ? "Invalid Response: #{response.body}" : msg)
      end
    end
  end
end
