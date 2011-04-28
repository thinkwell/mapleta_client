module Maple::MapleTA
module Page

  class Solution < Base


    def content_node
      @content_node ||= @page.parser.at_css('div.announce')
    end


    def validate
      node = @page.parser
      content_node  or raise Errors::UnexpectedContentError.new(node, "Cannot find page content")

      true
    end

  end

end
end
