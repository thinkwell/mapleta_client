module Maple::MapleTA
  module Errors
    class NotConnectedError < MapleTAError
      def initialize(msg=nil)
        super(msg.nil? ? 'Not Connected' : msg)
      end
    end
  end
end
