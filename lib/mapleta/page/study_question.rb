module Maple::MapleTA
module Page

  class StudyQuestion < BaseQuestion

    # Returns true if the given page looks like a page this class can parse
    def self.detect(page)
      return false unless form = page.parser.at_xpath('.//form[@name="edu_form"]')
      return false unless form['action'] =~ /tutorial/
      page.parser.xpath(".//input[@name='actionID' and (@value='grade' or @value='viewgrade' or @value='viewdetails')]").length == 0
    end

  end

end
end
