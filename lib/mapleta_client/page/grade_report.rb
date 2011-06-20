module Maple::MapleTA
module Page

  class GradeReport < Base
    include Form

    attr_reader :student_id

    # Returns true if the given page looks like a page this class can parse
    def self.detect(page)
      page.parser.css('div#gradeContent').length > 0 &&
        page.parser.css('table.detailsTable').length > 0
    end


    def self.fetch(connection, try_id, user_login=nil, view_opts={})
      connection.launcher('gradeBook')
      user_login ||= connection.user_login
      page = connection.fetch_page('gradebook/Details.do', {
        'userId' => user_login,
        'trId' => try_id,
      })
      self.new(page, view_opts)
    end


    # Update individual question grades.
    #
    # This method is very inefficient.  It submits a seperate request to Maple for
    # each question grade that is changed.  Because of this, it tries to be smart
    # by only sending changes.
    # TODO: Find a better way to submit question grade changes.
    #
    def self.update_grade_items(connection, try_id, user_login, params, page=nil)
      page ||= self.fetch(connection, try_id, user_login)
      student_id = page.student_id
      question_update_count = 0

      params.each do |key, val|
        if key =~ /^grade(\d+)_(\d+)$/ && $2.to_i == try_id
          position = $1.to_i
          grade = val
          comment = params["comment#{position}_#{try_id}"]

          grade = nil if grade.blank?
          grade = grade.to_f if grade
          comment = nil if comment.blank?
          comment.strip! if comment

          if grade.nil? && (comment.to_s != page.question_comment(position + 1).to_s)
            # The teacher changed the comment, but did not change the grade.
            # If we send nothing as the grade, Maple will change the grade to 0.
            # We need to use the existing grade.
            grade = page.question_score(position + 1)
          end

          unless grade.nil?
            maple_params = {
              'userId' => student_id,
              'classId' => connection.class_id,
              'detailView' => 'view.instructor.details',
              'trId' => try_id,
              'position' => position,
              'grade' => grade,
              'comment' => comment.nil? ? ' ' : comment,
            }

            #Rails.logger.warn("UPDATING GRADE: #{maple_params.inspect}")
            return_page = connection.fetch_page('gradebook/UpdateGradeItem.do', maple_params, :post)
            question_update_count += 1
            # TODO: Check the return page for errors
          end
        end

        question_update_count
      end

    end


    def initialize(page, opts={})
      fix_invalid_html_first!(page)
      super
    end


    def html
      grade_questions_node.to_xhtml
    end


    def score
      return @score if @score
      if score_node.text =~ /(\d+)\/(\d+(?:\.\d*)?)/
        @score = $1.to_i
      end
      @score
    end


    # Return the non-weighted question score for the given question number.
    # NOTE: question_num is indexed from 1.
    def question_score(question_num)
      qnode = question_node_for(question_num)
      label_node = qnode.at_xpath('.//strong[text()="Question Grade:"]')
      if label_node
        td_node = label_node.parent
        td_node = td_node.parent unless td_node.node_name == 'td'
        if td_node
          return td_node.next_element.inner_text.strip.to_f
        end
      end
      nil
    end


    # Return the instructor comment for the given question number.
    # NOTE: question_num is indexed from 1.
    def question_comment(question_num)
      qnode = question_node_for(question_num)
      label_node = qnode.at_xpath('.//strong[text()="Instructors Comment:"]')
      if label_node
        tr_node = label_node.parent.parent
        tr_node = tr_node.parent unless tr_node.node_name == 'tr'
        if tr_node
          return tr_node.next_element.at_xpath('./td/textarea').text.strip
        end
      end
      nil
    end


    def finished
      @finished ||= Time.parse(finished_node.text)
    end


    def grade_content_node
      @grade_content_node ||= page.parser.at_css('div#gradeContent')
    end


    def grade_questions_node
      @grade_questions_node ||= grade_content_node.at_css('div.maple_grade_report_questions')
    end


    # NOTE: question_num is indexed from 1
    def question_node_for(question_num)
      @grade_questions_node.xpath('./*[contains(@class, "question")]')[question_num - 1]
    end


    def score_node
      @score_node ||= page.parser.at_css('#asgnDetailTotalScore')
    end


    def finished_node
      unless @finished_node
        label_node = page.parser.at_xpath('.//div[@id="gbkTRInfoTable"]//td[@class="userInfoTitle"]/strong[text()="Finished:"]')
        if label_node
          @finished_node = label_node.parent.next_sibling
        end
      end
      @finished_node
    end


    def form_name
      'maple_grade_report_form'
    end



    def fix_html
      remove_question_number_cell
      remove_grade_icons
      remove_table_widths
      fix_padded_tables
      remove_history_links
      remove_grade_comment
      remove_form_javascript
    end


    def remove_question_number_cell
      grade_questions_node.xpath('./fieldset/table/tr/td[@class="position"]').remove
    end


    # Remove correct/incorrect icons
    def remove_grade_icons
      grade_questions_node.xpath('.//img[contains(@src, "/correct.gif") or contains(@src, "/incorrect.gif")]').each do |img_node|
        td_node = img_node.parent.parent rescue nil
        if td_node && td_node.node_name == 'td' && img_node.parent.node_name == 'div'
          td_node.remove
        end
      end
    end


    def remove_table_widths
      grade_questions_node.xpath('.//table[@width="650"]').each do |node|
        node.remove_attribute('width')
      end
    end


    def fix_padded_tables
      grade_questions_node.css('table td.response > table').each do |node|

        # Tables with only one row are easy, just remove the empty padding cells
        if node.xpath('./tr').length == 1
          node.xpath('./tr/td[@width="20"]').each do |td|
            td.remove if td.children.length == 0
          end
        end

        # Some question types have two rows, with padding cells in the second
        # row and a single colspan cell in the first row
        if node.xpath('./tr').length == 2
          tr1 = node.xpath('./tr')[0]
          tr2 = node.xpath('./tr')[1]
          if tr1.xpath('./td').length == 1
            tr2.xpath('./td[@width="20"]').each do |td|
              td.remove if td.children.length == 0
            end
            if td = tr1.at_xpath('./td[@colspan]')
              td['colspan'] = tr2.xpath('./td').length.to_s
            end
          end
        end
      end

    end


    def remove_history_links
      grade_questions_node.xpath('.//a[text()="View History"]').each do |node|
        tr_node = node.parent.parent rescue nil
        if tr_node && tr_node.node_name == 'tr'
          tr_node.remove
        else
          node.remove
        end
      end
    end


    def remove_grade_comment
      grade_questions_node.xpath('.//tr/td/strong[text()="Comment on Grade:"]').each do |node|
        tr_node = node.parent.parent rescue nil
        if tr_node && tr_node.node_name == 'tr'
          tr_node.next_sibling.remove
          tr_node.remove
        end
      end
    end


    def remove_form_javascript
      form_node.xpath('.//input[@onkeyup]').each do |node|
        node.remove_attribute('onkeyup')
      end
    end


    def remove_form_inputs
      form_node.xpath('.//tr/td/strong[text()="New Question Grade:"]').each do |node|
        tr_node = node.parent.parent rescue nil
        tr_node.remove if tr_node && tr_node.node_name == 'tr'
      end
      grade_questions_node.xpath('.//tr/td/strong[text()="Instructors Comment:"]').each do |node|
        tr_node = node.parent.parent rescue nil
        if tr_node && tr_node.node_name == 'tr'
          comment_tr = tr_node.next_sibling
          if comment_tr
            comment_tr.xpath('./td/textarea').each do |node|
              new_node = @page.parser.create_element 'div'
              new_node['style'] = "max-width: 400px;"
              new_node.inner_html = node.text
              node.add_next_sibling new_node
              node.remove
            end
          end
        end
      end
    end



  private

    def mandatory_fixes
      find_student_id
      fix_grade_tables
      add_grade_form
    end



    def fix_invalid_html_first!(page)

      # Multiple selection questions contain invalid html that looks like this:
      #  1  <td class="response">
      #  2    <table><tr><td>
      #  3    <table>
      #  4      <tr>
      #  5        <td>...</td>
      #  6        <table><tr><td>...</td></tr></table>
      #  7        <td>...</td>
      #  8      </tr>
      #  9      <tr><td>...</tr></td>
      # 10    </table>
      # 11  </td>
      #
      # There are 3 problems above:
      # 1) Unmatched "<table><tr><td>" (line 2)
      # 2) Improperly placed table element (line 6)
      # 3) Reversed closing tags ("</tr></td>") (line 9)
      #
      # Attempt to fix this with:
      #  1  <td class="response">
      #  2
      #  3    <table>
      #  4      <tr>
      #  5        <td>...<table><tr><td>...</td></tr></table></td>
      #  6
      #  7        <td>...</td>
      #  8      </tr>
      #  9      <tr><td>...</td></tr>
      # 10    </table>
      # 11  </td>
      #
      page.body = page.body.gsub("<td class=\"response\">\n\t\t<table><tr><td><table><tr><td>", "<td class=\"response\">\n\t\t<table><tr><td>")
      page.body = page.body.gsub('</td><table', '<table')
      page.body = page.body.gsub('</table><td', '</table></td><td')
      page.body = page.body.gsub('</tr></td>', '</td></tr>')

      # HACK: reset the Mechanize parser so Nokogiri will re-parse the html
      # body
      page.instance_variable_set(:@parser, nil)
    end


    def find_student_id
      @student_id = page.parser.at_xpath('.//input[@name="studentid"]')['value'].to_i
    end



    # Remove the table container, placing individual question tables inside
    # a surrounding div
    #
    # WARNING: This is called from initialize, and should not be called from
    # fix_html.
    # In other words, this fix is not optional and is required for this page to
    # function properly
    #
    def fix_grade_tables
      old_node = grade_content_node.at_css('table.detailsTable')
      new_node = @page.parser.create_element 'div'
      new_node['class'] = 'maple_grade_report_questions'
      old_node.add_next_sibling(new_node)
      @grade_questions_node = new_node

      odd_even = ['odd', 'even']
      old_node.xpath('./tr[@class="odd" or @class="even"]/td/table[@width="100%"]').each_with_index do |table_node, i|
        new_container = @page.parser.create_element 'fieldset'
        new_container['class'] = "question #{odd_even[i%2]}"
        new_container.inner_html = "<legend class=\"header\"><span class=\"name question_name\">Question #{i+1}</span></legend>"
        if table_node.xpath('.//td[@class="response"]//img[contains(@src, "/incorrect.gif")]').length > 0
          new_container['class'] += ' incorrect'
        elsif table_node.xpath('.//td[@class="response"]//img[contains(@src, "/correct.gif")]').length > 0
          new_container['class'] += ' correct'
        end
        new_container.parent = new_node

        table_node.remove_attribute('width')
        table_node.parent = new_container
      end

      old_node.remove
    end


    # Wrap the grade_questions_node in a dummy form.  This allows the Form
    # module to work, but this form should never be submitted.
    def add_grade_form
      new_node = @page.parser.create_element 'form'
      new_node['action'] = '/mapleta/gradebook/UpdateGradeItem.do'
      new_node['name'] = self.form_name
      new_node['method'] = 'post'
      grade_questions_node.replace new_node
      grade_questions_node.parent = new_node
    end


    def validate
      node = @page.parser
      content_node or raise Errors::UnexpectedContentError.new(node, "Cannot find report content")
      grade_content_node or raise Errors::UnexpectedContentError.new(node, "Cannot find grade content")
    end

  end

end
end
