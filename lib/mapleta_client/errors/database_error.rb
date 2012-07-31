module Maple::MapleTA
  module Errors
    class DatabaseError < MapleTAError
      attr_reader :original_error

      def initialize(msg=nil, original_error=nil)
        @original_error = original_error
        super(msg.nil? ? original_error.message.strip : msg)
      end
    end
  end
end
