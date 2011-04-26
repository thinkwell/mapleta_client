module Maple::MapleTA
module Page

  class RestrictedAssignment < Base

    # Returns true if the given page looks like a page this class can parse
    def self.detect(page)
      !!(page.parser.at_xpath('.//title').text() =~ /Restricted Assignment/)
    end


    def initialize(page, opts={})
      super
      fix_reason_node
    end

    def html
      reason_node.children.map { |x| x.to_xhtml }.join
    end


    def fix_html
    end

    def reason_node
      @reason_node ||= @page.parser.at_css('div.reason')
    end


  private


    # Wrap the description content (starting with first p, ending with form)
    # in a reason node
    #
    # WARNING: This is called from initialize, and should not be called from
    # fix_html.
    # In other words, this fix is not optional and is required for this page to
    # function properly
    def fix_reason_node
      new_node = nil
      content_node.children.each do |node|
        if new_node == nil
          if node.name == "p"
            new_node = @page.parser.create_element 'div'
            new_node['class'] = 'reason'
            node.add_previous_sibling(new_node)
            node.parent = new_node
          end
        else
          break if node.name == "form"
          next if node.name == "br"
          next if node.children.length == 0 && !node.text?
          node.xpath('.//br').remove if node.name == 'table'
          node.parent = new_node
        end
      end
    end


    def validate
      node = @page.parser
      content_node or raise Errors::UnexpectedContentError.new(node, "Cannot find content node")

      true
    end
  end

end
end
