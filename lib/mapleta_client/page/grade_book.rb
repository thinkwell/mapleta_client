module Maple::MapleTA
module Page

  class GradeBook < Base

    # Returns true if the given page looks like a page this class can parse
    def self.detect(page)
      page.parser.xpath('//form[@id="viewSearchForm"]').length > 0 &&
        page.parser.xpath('//div[@id="gradeContent"]').length > 0
    end


    def grade_table_node
      @grade_table_node ||= page.parser.at_css('div#gradeContent table.gradesTable')
    end


    #
    # Converts the grade_table_node into a data structure (keyed by assignment
    # id):
    #
    # {
    #   3: {
    #     'blt04': [
    #       {Grade: 100, Start: #<Time>, End: #<Time>, trId: 4},
    #       {Grade:  95, Start: #<Time>, End: #<Time>, trId: 1},
    #     ],
    #     'paloc@thinkwell.com': [
    #       {Grade: 100, Start: #<Time>, End: #<Time>, trId: 5},
    #       {Grade:  75, Start: #<Time>, End: #<Time>, trId: 3},
    #     ],
    #   },
    #   4: {
    #     'blt04': [
    #       ...
    #     ],
    #     'paloc@thinkwell.com': [
    #       ...
    #     ]
    #   }
    # }
    #
    def grade_table
      return {} unless grade_table_node
      return @data if @data
      data = {}
      n = grade_table_node

      # Parse the assignment headers
      assignment_cols = []
      n.css('thead tr.asgnHeader td.gradeColumn').each do |header|
        if header.inner_html =~ /assignmentSelection=(\d+)/
          assignment_cols << $1.to_i
          data[$1.to_i] = {}
        else
          raise Errors::GradeBookError "Cannot find assignment id for grade table column"
        end
      end

      # Parse the column headers
      cols = []
      n.at_css('thead tr.header td.gradeColumn').css('table.gradeData td').each do |header|
        cols << header.text
      end

      # Parse user rows
      n.css('tbody tr.userRowHover').each do |row|

        # Find the user name for this row
        user_node = row.at_css('td.userInfo a.userLink')
        if user_node['href'] =~ /'userId=([^']+)'/
          user_id = $1
          data.each {|key, val| val[user_id] = [] }
        else
          raise Errors::GradeBookError "Cannot find user id for grade table row"
        end

        # Process each assignment column for the user
        # TODO: Better way than using the "borderLeft" class?
        row.css('td.borderLeft').each_with_index do |assignment_col, i|
          assignment_id = assignment_cols[i]

          # Process each attempt row
          assignment_col.css('table.gradeData tr').each do |attempt_row|
            obj = {}
            attempt_row.css('td').each_with_index do |col_data, i|
              val = col_data.text.strip

              # Try to cast the value into the correct datatype
              val = val.to_i if val =~ /^\d+$/
              val = val.to_f if val =~ /^\d+\.(\d+)?$/
              val = Time.parse(val) if val =~ /^\d+\/\d+\/\d+(\s+\d+:\d+:\d+\s*(AM|PM))?$/

              obj[cols[i]] = val
            end

            # Special check to find the try ID
            if grade_node = attempt_row.at_css('a.grade')
              obj['trId'] = $1.to_i if grade_node['href'] =~ /trId=(\d+)/
            end

            data[assignment_id][user_id] << obj unless obj.length == 1 && obj.first[1] == '-'
          end
        end

      end

      @data = data
    end


    def assignment_selection_node
      @assignment_selection_node ||= page.parser.at_css('select#assignmentSelection')
    end


    def assignment_selections
      unless @assignment_selections
        @assignment_selections = []
        assignment_selection_node.xpath('./option').each do |option|
          h = {}
          h[:name] = $1 if option.text.strip =~ /^(.+)(\s+)-(\s+)(Reworkable )?(Proctored|Homework\/Quiz|Mastery)$/
          h[:value] = option['value'].to_i
          h[:mode] = $1 if option['class'] =~ /mode-(\d+)/
          @assignment_selections << h
        end
      end
      @assignment_selections
    end




  private

    def validate
      node = @page.parser
      content_node or raise Errors::UnexpectedContentError.new(node, "Cannot find error content")
      assignment_selection_node or raise Errors::UnexpectedContentError.new(node, "Cannot find assignment selections")
    end

  end

end
end
