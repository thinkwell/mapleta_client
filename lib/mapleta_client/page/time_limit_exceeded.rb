module Maple::MapleTA
module Page

  class TimeLimitExceeded < Base
    include Form

    def self.detect(page)
      return false unless form = page.parser.at_xpath('.//form[@name="edu_form"]')
      page.parser.at_css('div.content').text.include?('exceeded the maximum allowed time')
    end

  end

end
end
