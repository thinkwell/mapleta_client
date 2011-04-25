module Maple::MapleTA
module Page

  class Preview < Base
    def html
      "<table class=\"preview\">#{table_node.children.map { |x| x.to_xhtml }.join}</table>"
    end

    def table_node
      @page.parser.at_css('table')
    end

    def fix_html
    end

  private

    def validate
      node = @page.parser
      table_node or raise Errors::UnexpectedContentError.new(node, "Cannot find preview table")

      true
    end

  end

end
end
