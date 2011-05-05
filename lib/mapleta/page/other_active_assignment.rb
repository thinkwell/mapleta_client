module Maple::MapleTA
module Page

  class OtherActiveAssignment < Base
    include Form

    # Returns true if the given page looks like a page this class can parse
    def self.detect(page)
      return false unless form = page.parser.at_xpath('.//form[@name="edu_form" and @action="modules/test.WhichTest"]')
      form.text.include?('an active assignment in the system')
    end


    def initialize(page, opts={})
      super
      fix_reason_node
    end


    def html
      reason_node.children.map { |x| x.to_xhtml }.join
    end


    def old_test_id
      return @old_test_id if @old_test_id
      node = form_node.at_xpath(".//input[@name=\"#{form_name_for 'oldTestId'}\"]")
      @old_test_id = node && node['value'].to_i
    end


    def reason_node
      @reason_node ||= @page.parser.at_css('div.reason')
    end

    def allow_resume_old?
      form_node.xpath('.//input[@value="ALLOW_RE_ENTRY"]').length > 0
    end


    def allow_grade_old?
      form_node.xpath('.//input[@value="ALLOW_GRADING"]').length > 0
    end


    def allow_grade_and_continue?
      form_node.xpath('.//input[@value="ALLOW_NEW_TEST"]').length > 0
    end


  private


    # Wrap the description content (everything after the first font inside the
    # form tag) in a reason node
    #
    # WARNING: This is called from initialize, and should not be called from
    # fix_html.
    # In other words, this fix is not optional and is required for this page to
    # function properly
    def fix_reason_node
      new_node = nil
      form_node.children.each do |node|
        if new_node == nil
          if node.name == "font"
            new_node = @page.parser.create_element 'div'
            new_node['class'] = 'reason'
            node.add_previous_sibling new_node
            node.parent = new_node
          end
        else
          next if node.name == 'br'
          next if node.children.length == 0 && !node.text?
          next if node.children.length == 1 && node.children[0].text? && node.children[0].text =~ /^\s*$/
          node.parent = new_node
        end
      end
    end


    def validate
      node = @page.parser
      content_node  or raise Errors::UnexpectedContentError.new(node, "Cannot find question content")
      form_node     or raise Errors::UnexpectedContentError.new(node, "Cannot find question form")
      true
    end

  end

end
end
