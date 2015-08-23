module Maple::MapleTA
module Page

  class Question < BaseQuestion

    # Returns true if the given page looks like a page this class can parse
    def self.detect(page)
      !page.parser.at_css('input[@type="hidden"][name="questionId"]').nil?
    end

  end

end
end
