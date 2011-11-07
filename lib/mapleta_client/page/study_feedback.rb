module Maple::MapleTA
module Page

  class StudyFeedback < Base

    def content_node
      @content_node ||= @page.parser.at_css('div.announce')
    end


    private

    def mandatory_fixes
      add_wrapper_div
    end


    def add_wrapper_div
      new_node = @page.parser.create_element 'div'
      new_node['class'] = 'feedback'
      content_node.children.each do |node|
        if node.name == "h3"
          if node.text =~ /Correct/
            new_node['class'] += ' correct'
          elsif node.text =~ /Incorrect/
            new_node['class'] += ' incorrect'
          end
        end
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
