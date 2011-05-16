module Maple::MapleTA
  module Errors
    class NotFoundError < MapleTAError
      def initialize(msg=nil)
        super(msg.nil? ? 'Not Found' : msg)
      end
    end
  end
end
