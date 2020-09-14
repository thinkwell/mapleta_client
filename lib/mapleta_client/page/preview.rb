module Maple::MapleTA
module Page

  class Preview < Base
    def html
      html = "<table class=\"preview\">#{table_node.children.map { |x| x.to_xhtml }.join}</table>"
      use_secure_image_proxy html
    end

    def table_node
      @page.parser.at_css('table')
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
