module Maple::MapleTA
module Page

  class GradeReport < Base
    include Form

    attr_reader :student_id

    # Returns true if the given page looks like a page this class can parse
    def self.detect(page)
      page.parser.css('div#gradeContent').length > 0 &&
        page.parser.css('table.detailsTable').length > 0 &&
        page.parser.xpath('.//input[@name="studentid"]').length > 0
    end


    def self.fetch(connection, try_id, user_login=nil, view_opts={})
      connection.launcher('gradeBook')
      user_login ||= connection.user_login
      page = connection.fetch_page('gradebook/Details.do', {
        'userId' => user_login,
        'trId' => try_id,
        'numberOfRows' => 250,
      })
      raise Errors::UnexpectedContentError.new(page.parser, "Cannot detect page type") unless self.detect(page)
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
      remove_history_links
      remove_grade_comment
      remove_form_javascript
      remove_update_grade_toggles
      remove_update_icons
      fix_question_response
    end


    def remove_question_number_cell
      grade_questions_node.xpath('./fieldset/table/tr/td[@class="position"]').remove
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


    def remove_update_grade_toggles
      form_node.xpath('.//tr/td/div/a[starts-with(@onclick, "toggleItem(\'gbkUpdate")]').each do |node|
        node.parent.remove
      end
    end


    def remove_update_icons
      form_node.xpath('.//tr/td/span/a[starts-with(@onclick, "updateItem")]').each do |node|
        node.parent.remove
      end
    end


    def fix_question_response
      grade_questions_node.xpath('./fieldset/table/tr/td[@class="response"]').each do |response_node|
        # Detect response type
        if response_node.xpath('./table').length == 1 && response_node.xpath('./table/tr').length == 3 && response_node.xpath('./table/tr[1]/td/table/tr[1]/th[@bgcolor]').length > 0
          fix_two_column_response response_node
        elsif response_node.xpath('./table').length == 1 && response_node.xpath('./table/tr[1]/td[1][@colspan="2"]').length == 1
          fix_multipart_response response_node
        elsif response_node.xpath('./table').length == 2
          fix_row_response response_node
        end
      end
    end


    def fix_two_column_response(node)
      # Remove empty padding cells
      node.xpath('./table/tr/td[1]').each {|td| td.remove if td.children.length == 0}

      column_table = node.at_xpath('./table/tr[1]/td/table')
      # Remove column table attributes
      column_table.remove_attribute('width')
      column_table.remove_attribute('cellpadding')
      column_table.xpath('.//th[@bgcolor]').remove_attr('bgcolor')

      # Remove correct/incorrect icon
      column_table.xpath('./tr/td[div/img[contains(@src, "/correct.png") or contains(@src, "/incorrect.png")]]').remove

      # Remove total grade
      node.xpath('.//p[*="Total grade:"]').remove
      node.xpath('.//p').each {|p| p.remove if p.children.length == 0}

      # Change comment rows from:
      #   <tr><td>Comment:</td></tr>
      #   <tr><td>...comment html...</td></tr>
      # to:
      #   <tr><td><table><tr>
      #     <td>Comment:<td>
      #     <td>...comment html...</td>
      #   </tr></table></td></tr>
      if node.xpath('./table/tr[2]/td[*="Comment:"]').length > 0
        new_tr = @page.parser.create_element 'tr'
        new_tr.inner_html = '<td><table><tr></tr></table></td>'
        inner_tr = new_tr.at_xpath('./td/table/tr')
        node.at_xpath('./table/tr[2]/td').parent = inner_tr
        node.at_xpath('./table/tr[3]/td').parent = inner_tr
        node.at_xpath('./table/tr[3]').remove
        node.at_xpath('./table/tr[2]').remove
        new_tr.xpath('.//td').remove_attr('colspan')
        new_tr.parent = node.at_xpath('./table')
        add_class inner_tr, './td[1]', 'question-explanation-label'
        add_class inner_tr, './td[2]', 'question-explanation'
      end

      # Add classes
      add_class node, '.', 'column-layout'
      add_class node, './table/tr[1]', 'response-row'
      add_class node, './table/tr[2]', 'question-explanation-row'
      if label = column_table.at_xpath('./tr[1]/th[text()="Your response"]')
        col_num = column_table.xpath('./tr[1]/th').index(label) + 1
        add_class column_table, "./tr[1]/th[#{col_num}]", 'student-answer-label'
        add_class column_table, "./tr[2]/td[#{col_num}]", 'student-answer'
      end
      if label = column_table.at_xpath('./tr[1]/th[text()="Correct response"]')
        col_num = column_table.xpath('./tr[1]/th').index(label) + 1
        add_class column_table, "./tr[1]/th[#{col_num}]", 'correct-answer-label'
        add_class column_table, "./tr[2]/td[#{col_num}]", 'correct-answer'
      end
      add_class column_table, './tr[2]/td', 'question-stem'
    end


    def fix_row_response(node)
      # Remove empty padding cells
      node.xpath('./table/tr/td[@width="20"]').each {|td| td.remove if td.children.length == 0}
      #node.xpath('./table').each do |table|
      #  if table.xpath('./tr').length == 1
      #    # Tables with only one row are easy, just remove the empty padding cells
      #    table.xpath('./tr/td[@width="20"]').each {|td| td.remove if td.children.length == 0}
      #
      #  elsif table.xpath('./tr').length == 2
      #    # Some question types have two rows, with padding cells in the second
      #    # row and a single colspan cell in the first row
      #    tr1 = table.at_xpath('./tr[1]')
      #    tr2 = table.at_xpath('./tr[2]')
      #    if tr1.xpath('./td').length == 1
      #      tr2.xpath('./td[@width="20"]').each {|td| td.remove if td.children.length == 0}
      #      if td = tr1.at_xpath('./td[@colspan]')
      #        td['colspan'] = tr2.xpath('./td').length.to_s
      #      end
      #    end
      #  end
      #end

      # Remove correct/incorrect icon
      node.xpath('./table/tr/td[div/img[contains(@src, "/correct.png") or contains(@src, "/incorrect.png")]]').remove

      # Remove partial grading
      node.xpath('.//tr[*="Partial Grading Explained"]').remove

      # Add classes
      add_class node, '.', 'row-layout'
      add_class node, './table[1]/tr[1]', 'question-row'
      add_class node, './table[1]/tr[1]/td', 'question-stem'
      add_class node, './/tr[*="Your Answer:"]', 'student-answer-row'
      add_class node, './/td[*="Your Answer:"]', 'student-answer-label'
      add_class node, './/tr[td[*="Your Answer:"]]/td[2]', 'student-answer'
      add_class node, './/tr[*="Correct Answer:"]', 'correct-answer-row'
      add_class node, './/td[*="Correct Answer:"]', 'correct-answer-label'
      add_class node, './/tr[*="Correct Answer:"]/td[2]', 'correct-answer'
      add_class node, './/tr[*="Comment:"]', 'question-explanation-row'
      add_class node, './/td[*="Comment:"]', 'question-explanation-label'
      add_class node, './/tr[*="Comment:"]/td[2]', 'question-explanation'
    end


    def fix_multipart_response(node)
      node.xpath('./table').remove_attr 'cellpadding'
      add_class node, '.', 'multipart-layout'
      add_class node, './table/tr[1]', 'question-row'

      # Cycle through each part
      (2..(node.xpath('./table/tr').length)).each do |i|
        tr = node.at_xpath("./table/tr[#{i}]")
        if tr.xpath('./td[1][@colspan="2"]').length == 1
          # Comment
          add_class tr, '.', 'multipart-explanation-row'

        elsif tr.xpath('./td[1][@valign="top"]').length == 1
          # Question Response
          add_class tr, '.', 'multipart-response-row'
          tr.at_xpath('./td[1]').remove_attribute('valign')
          add_class tr, './td[1]', 'multipart-response-label'

          # Detect response type
          response_node = tr.at_xpath('./td[2]')
          if response_node.xpath('./table').length == 1 && response_node.xpath('./table/tr[1]/td/table/tr[1]/th[@bgcolor]').length > 0
            fix_two_column_response response_node
          elsif response_node.xpath('./table/tr[1]/td[2]//img[contains(@src, "/correct.png") or contains(@src, "/incorrect.png")]').length == 1
            fix_row_response response_node
          end
        end
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
      # The Grade Report page contains some invalid HTML that causes NokoGiri
      # to choke.  We attempt to fix this with simple substitutions before
      # NokoGiri parses the document body.

      # Multiple selection questions contain invalid html that looks like this:
      #  1 <table>
      #  2   <tr>
      #  3     <td>
      #  4       <p>...</p>
      #  5       <P>
      #  6     </td>
      #  7
      #  8
      #  9     <table cellpadding=4 border=1>...</table>
      #
      # The table element on line 9 is in an invalid place.
      # We fix this by properly closing the previous table.  We also remove the
      # empty P element (line 5) as it isn't needed.
      #
      #  1 <table>
      #  2   <tr>
      #  3     <td>
      #  4       <p>..</p>
      #  5
      #  6     </td>
      #  7   </tr>
      #  8 </table>
      #  9 <table cellpadding=4 border=1>...</table>
      #
      page.body.gsub!('<P></td><table cellpadding=4 border=1>', '</td></tr></table><table cellpadding=4 border=1>')

      # Partial grading table cells are closed using tags in the wrong order
      # ("</tr></td>").
      # We fix this by converting to "</td></tr>".
      #
      page.body.gsub!('Partial Grading Explained</font></A></tr></td>', 'Partial Grading Explained</font></A></td></tr>')

      # Other random invalid HTML fixes
      page.body.gsub!('</TD></TD>', '</TD>')
      page.body.gsub!('</TR></TR>', '</TR>')


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
        if table_node.xpath('.//td[@class="response"]//img[contains(@src, "/incorrect.png")]').length > 0
          new_container['class'] += ' incorrect'
        elsif table_node.xpath('.//td[@class="response"]//img[contains(@src, "/correct.png")]').length > 0
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
