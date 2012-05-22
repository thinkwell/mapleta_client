module Maple::MapleTA
module Page

  class Solution < Base


    def content_node
      @content_node ||= @page.parser.at_css('div.announce')
    end

    private

    def mandatory_fixes
      add_wrapper_div
    end

    def add_wrapper_div
      new_node = @page.parser.create_element 'div'
      new_node['class'] = 'solution'
      content_node.children.each do |node|
        node.parent = new_node
      end
      content_node.add_child new_node
    end

    def validate
      node = @page.parser
      content_node  or raise Errors::UnexpectedContentError.new(node, "Cannot find page content")

      true
    end

  end

end
end
