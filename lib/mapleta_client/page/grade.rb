module Maple::MapleTA
module Page

  class Grade < Base
    include Form

    # Returns true if the given page looks like a page this class can parse
    def self.detect(page)
      return false unless form = page.parser.at_xpath('.//form[@name="edu_form"]')
      return false if form['action'] =~ /sequentialTest\.QuestionSheet/
      return false unless form['action'] =~ /QuestionSheet|gradeProctoredTest|TestDetails/
      return false if page.parser.xpath('.//th[text()="Topic"]').length != 0 && page.parser.xpath('.//th[text()="% of Requirements"]').length != 0
      form['action'] =~ /gradeProctoredTest/ ||
        page.parser.xpath(".//input[@name='actionID' and (@value='grade' or @value='viewgrade' or @value='viewdetails')]").length > 0
    end



    # One of :confirm, :grade, :details
    def state
      if form_node.xpath(".//input[@name='#{form_name_for('actionID')}' and @value='viewdetails']").length > 0
        :details
      elsif form_node.xpath(".//input[@name='#{form_name_for('really-grade')}']").length > 0
        :confirm
      else
        :grade
      end
    end


    def title
      case state
      when :confirm
        "Grade?"
      when :details
        "Grade Details Report"
      else
        "Grade Report"
      end
    end


    # Returns true when this page is being displayed as a result of the assignment
    # being graded (not just as a result of the viewing the grade, or toggling between
    # grade view and details view)
    #
    def just_graded?(maple_request_params)
      return false unless maple_request_params.is_a?(Hash)

      # Unfortunately the only way to know why this page is being displayed is to look
      # the request parameters that resulted in this page being returned.
      #   * :actionID == 'grade' - The user clicked the Grade button and the assignment
      #     was graded as a result
      #   * :authType == 'ALLOW_GRADING' - The assignment required proctor authorization to
      #     be graded, which was provided by the proctor entering their username/password on
      #     the students computer
      #   * :modeRequested == 'ALLOW_GRADING' - The assignment required proctor authorization to
      #     be graded, which was provided remotely via proctor tools.
      state == :grade && (
        maple_request_params[:actionID] == 'grade' ||
        maple_request_params[:authType] == 'ALLOW_GRADING' ||
        maple_request_params[:modeRequested] == 'ALLOW_GRADING'
      )
    end


    ###
    # These methods return html snippets intended to be inserted directly in
    # a html page
    #

    def html
      # inner_xhtml
      grade_node.children.map { |x| x.to_xhtml }.join
    end
    alias :grade_html :html

    #
    ###



    ###
    # These methods return nokogiri nodes at various important points in the
    # question document
    #

    def grade_node
      @grade_node ||= form_node.xpath("./div[@style='margin: 10px']").last
    end

    #
    ###



    ###
    # These methods apply different fixes to the html returned from Maple
    #

    # Shortcut for applying all html fixes
    def fix_html
      fix_question_links
      fix_feedback_title
      fix_table_border
    end


    def fix_question_links
      form_node.xpath(".//a[contains(@href, 'doReturn')]").each do |node|
        if node['href'] =~ /javascript:\s*doReturn\((\d+)\)/
          node['href'] = "##{$1}"
          node['class'] = "goto"
        end
      end
    end


    def fix_feedback_title
      if feedback = grade_node.at_xpath('./b[contains(text(), "Feedback")]')
        feedback.remove
      end
    end


    def fix_table_border
      grade_node.xpath(".//table[@border=1]").each do |node|
        node.remove_attribute 'border'
        node['class'] = "#{node['class']} with-border"
      end
      grade_node.xpath(".//table[@cellpadding]").each do |node|
        if node['cellpadding'].to_i > 10
          node['class'] = "#{node['class']} with-large-padding"
        else
          node['class'] = "#{node['class']} with-small-padding"
        end
        node.remove_attribute 'cellpadding'
      end
    end

    #
    ###


  private

    def mandatory_fixes
      # Move hidden fields out of the grade node
      # This prevents duplicate hidden nodes when using question_html and hidden_fields_html
      grade_node.xpath(".//input[@type='hidden']").each {|node| node.parent = form_node}
    end


    def validate
      node = @page.parser
      form_node     or raise Errors::UnexpectedContentError.new(node, "Cannot find form")
      grade_node    or raise Errors::UnexpectedContentError.new(node, "Cannot find grade node")

      true
    end

  end

end
end
