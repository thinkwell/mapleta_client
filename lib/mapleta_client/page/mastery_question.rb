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


    def progress_report_node
      unless @progress_report_node
        @progress_report_node = page.parser.at_xpath('.//em[text()="Progress Report"]').next_element rescue -1
      end
      @progress_report_node == -1 ? nil : @progress_report_node
    end


    def progress_report_html
      progress_report_node ? progress_report_node.to_xhtml : ''
    end

  end

end
end
