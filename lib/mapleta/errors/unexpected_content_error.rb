module Maple::MapleTA
  module Errors
    class UnexpectedContentError < MapleTAError
      # Content should be a nokogiri Node
      attr_reader :node

      def initialize(node, msg=nil)
        @node = node
        super(msg.nil? ? "Unexpected content received from Maple T.A." : msg)
      end
    end
  end
end
