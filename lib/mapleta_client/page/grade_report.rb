module Maple::MapleTA
module Page

  class GradeReport < Base

    # Returns true if the given page looks like a page this class can parse
    def self.detect(page)
      page.parser.css('div#gradeContent').length > 0 &&
        page.parser.css('table.detailsTable').length > 0
    end


    def self.fetch(connection, try_id, view_opts={})
      connection.launcher('gradeBook')
      page = connection.fetch_page('gradebook/Details.do', {
        'userId' => connection.user_login,
        'trId' => try_id,
      })
      self.new(page, view_opts)
    end


    def initialize(page, opts={})
      fix_invalid_html_first!(page)
      super
      fix_grade_tables
    end


    def html
      grade_questions_node.to_xhtml
    end



    def grade_content_node
      @grade_content_node ||= page.parser.at_css('div#gradeContent')
    end


    def grade_questions_node
      @grade_questions_node ||= grade_content_node.at_css('div.maple_grade_report_questions')
    end


    def fix_html
      remove_question_number_cell
      remove_grade_icons
      remove_table_widths
      fix_padded_tables
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



  private


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


    def validate
      node = @page.parser
      content_node or raise Errors::UnexpectedContentError.new(node, "Cannot find report content")
      grade_content_node or raise Errors::UnexpectedContentError.new(node, "Cannot find grade content")
    end

  end

end
end
