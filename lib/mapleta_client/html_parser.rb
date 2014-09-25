module Maple::MapleTA
  class HtmlParser
    def self.parse body, url = nil, encoding = nil, options = Nokogiri::XML::ParseOptions::DEFAULT_HTML, &block
      body.gsub!(/(<)([^>]*<)/, '&lt;\2')
      Nokogiri::HTML::Document.parse(body, url, encoding, options, &block)
    end
  end
end