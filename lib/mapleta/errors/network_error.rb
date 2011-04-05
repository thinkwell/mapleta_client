module Maple::MapleTA
  module Errors
    class NetworkError < MapleTAError

      attr_reader :original_error

      def initialize(original_error, msg=nil)
        @original_error = original_error
        super(msg.nil? ? original_error.message : msg)
      end
    end
  end
end
