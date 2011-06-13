module Maple::MapleTA
module Page

  class Error < Base

    # Returns true if the given page looks like a page this class can parse
    def self.detect(page)
      return false unless title = page.parser.at_xpath('.//title')
      title.text =~ /Maple T\.A\..*Error/m &&
        page.parser.css('div.errorStyle1').length > 0
    end


    def error_node
      @error_node ||= content_node.at_css('.errorStyle1')
    end


    def html
      error_node.children.map { |x| x.to_xhtml }.join
    end


  private

    def validate
      node = @page.parser
      content_node  or raise Errors::UnexpectedContentError.new(node, "Cannot find error content")
      error_node or raise Errors::UnexpectedContentError.new(node, "Cannot find error description")
    end
  end

end
end
