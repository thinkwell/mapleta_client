module Maple::MapleTA
module Page

  class Feedback < Base
    include AnswerParser

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

    def solution
      # Look for solution under the heading of 'Comment:' first
      comment_row = content_node.xpath('//tr/td/b[text()="Comment:"]/../..')
      if comment_row && comment_row.xpath('./td').length == 1
        comment =  comment_row.first.next_element.xpath('./td')
      elsif comment_row && comment_row.xpath('./td').length > 1
        comment =  comment_row.xpath('./td[2]')
      else
        comment = nil
      end
      return comment unless comment.blank?

      # If the above produces nothing look for solution under the heading of 'Comments:'
      comment = content_node.xpath('//tr/td/b[text()="Comments:"]/..')
      comment.xpath('.//b[text()="Comments:"]').each{|c| c.remove }
      comment
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
