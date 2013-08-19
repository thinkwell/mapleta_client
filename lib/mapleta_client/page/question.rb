module Maple::MapleTA
module Page

  class Question < Base

    # Returns true if the given page looks like a page this class can parse
    def self.detect(page)
      !page.parser.at_css('input[@type="hidden"][name="questionId"]').nil?
    end

    def content_node
      @content_node ||= @page.parser.at_css('div[@class="questionstyle"]')
    end

    def validate
      node = @page.parser
      content_node or raise Errors::UnexpectedContentError.new(node, "Cannot find page content")
      true
    end
  end

end
end
