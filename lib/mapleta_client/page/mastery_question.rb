module Maple::MapleTA
module Page

  class MasteryQuestion < BaseQuestion

    # Returns true if the given page looks like a page this class can parse
    def self.detect(page)
      return false unless form = page.parser.at_xpath('.//form[@name="edu_form"]')
      return false unless form['action'] =~ /sequentialTest\.QuestionSheet/
      page.parser.xpath('.//script[contains(text(), "sequentialTest.Gradebar")]').length == 0
    end


    def is_question?
      !progress_report_node
    end


    def is_progress_report?
      !!progress_report_node
    end


    def allow_next?
      if is_question?
        allow_grade?
      else
        page.parser.xpath('.//td[contains(@class, "menuitem")]//a[contains(@href, "next")]').length > 0
      end
    end


    def allow_grade?
      page.parser.xpath('.//td[contains(@class, "menuitem")]//a[contains(@href, "grade")]').length > 0
    end


    def allow_finish?
      page.parser.xpath('.//td[contains(@class, "menuitem")]//a[contains(@href, "finishsession")]').length > 0
    end


    def total_questions
      if is_progress_report?
        progress_report.length
      else
        false
      end
    end


    def progress_report_node
      unless @progress_report_node
        @progress_report_node = page.parser.at_xpath('.//em[text()="Progress Report"]').next_element rescue -1
      end
      @progress_report_node == -1 ? nil : @progress_report_node
    end


    def progress_report_html
      progress_report_node ? progress_report_node.to_xhtml : ''
    end


    # Returns an array representing the progress report.  For example:
    #
    #   [
    #     {:title => 'Fraction Arithmetic', :requirement => :met,   :correct => 1, :incorrect => 0, :attempts => 1},
    #     {:title => 'Factorization',       :requirement => :begun, :correct => 0, :incorrect => 2, :attempts => 2},
    #     {:title => 'Easy Addition',       :requirement => false,  :correct => 0, :incorrect => 0, :attempts => 0},
    #   ]
    def progress_report
      return [] unless progress_report_node

      unless @progress_report_data
        @progress_report_data = []
        progress_report_node.xpath('./tr').each do |tr|
          next if tr['class'] && tr['class'].include?('head')

          row = {}
          row[:title] = tr.at_xpath('./td[2]').text

          status_class = tr.at_xpath('./td[3]')['class']
          if status_class && status_class.include?('mastery_requirement_met')
            row[:requirement] = :met
          elsif status_class && status_class.include?('mastery_requirement_begun')
            row[:requirement] = :begun
          else
            row[:requirement] = false
          end

          if tr.at_xpath('./td[4]').text =~ /(\d+)\/(\d+)/
            row[:correct] = $1.to_i
            row[:attempts] = $2.to_i
            row[:incorrect] = row[:attempts] - row[:correct]
          end

          @progress_report_data << row
        end
      end
      @progress_report_data
    end


    def progress_mastery
      return nil unless progress_report_node
      @progress_mastery ||= progress_report_node.at_xpath('./tr[last()]/th[4]').text
    end

  end

end
end
