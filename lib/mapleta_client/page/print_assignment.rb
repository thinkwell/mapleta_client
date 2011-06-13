module Maple::MapleTA
module Page

  class PrintAssignment < Base

    # Returns true if the given page looks like a page this class can parse
    def self.detect(page)
      page.parser.content.include?('PrintControlbar') &&
        page.parser.content.include?('Online Homework System')
    end


    def fix_html
      remove_script_nodes
      remove_style_nodes
    end


    def remove_script_nodes
      content_node.xpath('.//script').remove
    end


    def remove_style_nodes
      content_node.xpath('.//style').remove
    end


    def validate
      node = @page.parser
      content_node or raise Errors::UnexpectedContentError.new(node, "Cannot find page content")

      true
    end
  end

end
end
