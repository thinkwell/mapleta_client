module Maple::MapleTA
module Page

  class Feedback < Base


    def title
      return @title if @title

      node = @page.parser.at_xpath('.//div[@style="margin: 20px"]/font[@size="+1"]')
      if node && node.text =~ /(Question \d+:)\s*(Score.*)/
        @title = "#{$1} #{$2}"
      end
    end



    def content_node
      @page.parser.at_xpath('.//div[@style="margin: 20px"]')
    end


    def fix_html
      fix_table_border
      fix_hr_elements
    end


    def fix_table_border
      content_node.xpath(".//table[@border=1]").each do |node|
        node.remove_attribute 'border'
        node['class'] = "#{node['class']} with-border"
      end
      content_node.xpath(".//table[@cellpadding]").each do |node|
        if node['cellpadding'].to_i > 10
          node['class'] = "#{node['class']} with-large-padding"
        else
          node['class'] = "#{node['class']} with-small-padding"
        end
        node.remove_attribute 'cellpadding'
      end
    end


    def fix_hr_elements
      content_node.xpath('.//hr').remove
    end



  private

    def validate
      node = @page.parser
      content_node or raise Errors::UnexpectedContentError.new(node, "Cannot find content node")

      true
    end

  end

end
end
