module Maple::MapleTA
module Page

  class NumberHelp < Base

    # Returns true if the given page looks like a page this class can parse
    def self.detect(page)
      page.parser.content.include?('Number Help')
    end

    def content_node
      @content_node ||= @page.parser.at_css('div[@style="margin: 20px"]')
    end

    def validate
      node = @page.parser
      content_node or raise Errors::UnexpectedContentError.new(node, "Cannot find page content")
      true
    end
  end

end
end
