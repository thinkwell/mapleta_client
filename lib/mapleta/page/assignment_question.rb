module Maple::MapleTA
module Page

  class AssignmentQuestion < BaseQuestion

    # Returns true if the given page looks like a page this class can parse
    def self.detect(page)
      return false unless form = page.parser.at_xpath('.//form[@name="edu_form"]')
      return false unless form['action'] =~ /QuestionSheet/
      return false if page.parser.at_css('div.content').text.include?('exceeded the maximum allowed time')
      page.parser.xpath(".//input[@name='actionID' and (@value='grade' or @value='viewgrade' or @value='viewdetails')]").length == 0
    end



    def number
      @number || (parse_question_numbers && @number)
    end


    def total_questions
      @total_questions || (parse_question_numbers && @total_questions)
    end


    def question_list
      return @question_list if @question_list

      if question_list_node && question_list_node.content =~ /var pd = new Array\((.*)\);/
        @question_list = []
        $1.split(',').each do |val|
          @question_list << val.gsub(/^\s*"/, '').gsub(/"\s*$/, '')
        end
      end

      @question_list
    end


    def points
      return @points if @points
      if content_node.content =~ /Question \d+: \((\d+) point/
        @points = $1.to_i
      else
        @points = 0
      end
    end



    ###
    # These methods return nokogiri nodes at various important points in the
    # question document

    def question_list_node
      return @question_list_node if @question_list_node
      return nil if @question_list_node == false
      @question_list_node = @page.parser.xpath("//script[@language]").detect(false) do |node|
        node.content.include?('function initControlbar') && node.content.include?('var pd = new Array')
      end
    end

    #
    ###


  private

    def parse_question_numbers
      if content_node.content =~ /Question (\d+) of (\d+)/
        @total_questions = $2.to_i
        @number = $1.to_i
      else
        @number = @total_questions = 0
      end
    end

  end

end
end
