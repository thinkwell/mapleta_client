module Maple::MapleTA
module Page

  class PrintOrTake < Base
    include Form

    # Returns true if the given page looks like a page this class can parse
    def self.detect(page)
      return false unless form = page.parser.at_xpath('.//form[@name="edu_form" and contains(@action, ".Print")]')
      form.text.include?('Print assignment') && form.text.include?('Work assignment')
    end



    def html
      reason_node.children.map { |x| x.to_xhtml }.join
    end


    def reason_node
      @reason_node ||= @page.parser.at_css('div.reason')
    end


    def fix_html
      fix_links
    end

    def fix_links
      form_node.xpath('.//a[contains(@href, "javascript: doAction")]').each do |node|
        if node['href'] =~ /print assignment/
          node['data-action'] = 'print assignment now'
        elsif node['href'] =~ /work assignment now/
          node['data-action'] = 'work assignment now'
        end

        if node['data-action']
          node['href'] = '#'
          node['class'] = 'submit-form'
        end
      end
    end


    def validate
      node = @page.parser
      content_node or raise Errors::UnexpectedContentError.new(node, "Cannot find page content")
      form_node    or raise Errors::UnexpectedContentError.new(node, "Cannot find page form")

      true
    end



  private

    def mandatory_fixes
      fix_reason_node
    end


    # Wrap the description content (starting after the first table in
    # the form) in a reason node
    #
    # WARNING: This is called from initialize, and should not be called from
    # fix_html.
    # In other words, this fix is not optional and is required for this page to
    # function properly
    def fix_reason_node
      new_node = nil
      found_table = false
      form_node.children.each do |node|
        if new_node == nil
          if found_table
            new_node = @page.parser.create_element 'div'
            new_node['class'] = 'reason'
            node.add_previous_sibling new_node
            node.parent = new_node
          elsif node.name == "table"
            found_table = true
          end
        else
          next if node.name == 'br'
          next if node.children.length == 0 && !node.text?
          next if node.children.length == 1 && node.children[0].text? && node.children[0].text =~ /\A\s*\Z/
          node.parent = new_node
        end
      end
    end

  end

end
end
