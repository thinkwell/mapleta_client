module Maple::MapleTA
module Page

  class Question < Base
    include Form


    # Returns true if the given page looks like a page this class can parse
    def self.detect(page)
      page.parser.xpath(".//script[contains(@src, 'questionframe.js')]").length > 0 &&
        page.parser.xpath(".//input[@name='actionID' and (@value='grade' or @value='viewgrade' or @value='viewdetails')]").length == 0
    end


    def initialize(page, opts={})
      super

      # Move hidden fields out of the question node
      # This prevents duplicate hidden nodes when using question_html and hidden_fields_html
      question_node.xpath(".//input[@type='hidden']").each {|node| node.parent = form_node}
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


    def title
      # TODO: Can question title ever be something other than "Question \d"?
      "Question #{number}"
    end


    def points
      return @points if @points
      if content_node.content =~ /Question \d+: \((\d+) point/
        @points = $1.to_i
      else
        @points = 0
      end
    end


    def equation_entry_mode
      return @equation_entry_mode if @equation_entry_mode

      if form_node.xpath('.//applet[@code="applets.twodeeeditor.mathEditor"]').length > 0
        @equation_entry_mode = :symbol
      else
        @equation_entry_mode = :text
      end
    end



    ###
    # These methods return html snippets intended to be inserted directly in
    # a html page
    #

    def html
      # inner_xhtml
      question_node.children.map { |x| x.to_xhtml }.join
    end
    alias :question_html :html


    def script_html
      html = ''
      html << "#{base_url_script_node.to_html}\n" if base_url_script_node
      html
    end

    #
    ###



    ###
    # These methods return nokogiri nodes at various important points in the
    # question document
    #

    def error_node
      @error_node || @page.parser.at_css('div.errorStyle1')
    end


    def question_node
      #@question_node ||= form_node.at_xpath("./div[@style='margin: 10px']/table[last()]/tr/td[2]")
      @question_node ||= form_node.at_css("div.questionstyle")
    end


    def base_url_script_node
      return @base_url_script_node if @base_url_script_node
      return nil if @base_url_script_node == false
      @base_url_script_node = @page.parser.xpath('//script').detect(false) do |node|
        node.content.include?('function getBaseURL()')
      end
    end


    def question_list_node
      return @question_list_node if @question_list_node
      return nil if @question_list_node == false
      @question_list_node = @page.parser.xpath("//script[@language]").detect(false) do |node|
        node.content.include?('function initControlbar') && node.content.include?('var pd = new Array')
      end
    end

    #
    ###




    ###
    # These methods apply different fixes to the html returned from Maple
    #

    # Shortcut for applying all html fixes
    def fix_html
      fix_equation_entry_mode_links
      fix_preview_links
      fix_plot_links
      fix_help_links
      fix_image_position
    end


    def fix_equation_entry_mode_links
      form_node.xpath('.//a[text()="Change Entry Style"]').each do |node|
        case equation_entry_mode
        when :symbol
          node['href'] = "#text"
          node.content = "Switch to text input"
        when :text
          node['href'] = "#symbol"
          node.content = "Switch to Equation Editor"
        end
        node['class'] = 'change-equation-entry-mode'
      end
    end


    def fix_preview_links
      form_node.xpath('.//a[text()="Preview"]').each do |node|
        if node['href'] =~ /previewFormula\([^,]*getElementsByName\('([^']+)'\)[^,]*,.*'([^\)]+)'\)/
          node['href'] = "##{$1}"
          node['class'] = 'preview'
          node['maple_action'] = $2
        end
      end
    end


    def fix_plot_links
      form_node.xpath('.//a[text()="Plot"]').each do |node|
        if node['href'] =~ /popupMaplePlot\('(.+)'\s*,\s*document.getElementsByName\('([^']+)'\)[^']*,\s*'(.*)'\s*,\s*'(.*)'\s*,\s*'(.*)'\)/
          node['href'] = "##{$2}"
          node['class'] = 'plot'
          node['maple_maple'] = $1
          node['maple_type'] = $3
          node['maple_libname'] = $4
          node['maple_driver'] = $5
        end
      end
    end


    def fix_help_links
    end


    # Removes "vertical-align: -4px;" inline style that causes images to appear
    # lower than surrounding text
    def fix_image_position
      content_node.xpath('.//span[img and @style]').each do |node|
        node['style'] = node['style'].gsub(/vertical-align: -?\d+px;/, '')
      end
    end


    #
    ###

  private

    # Validates that the mechanize page contains a Maple T.A. question,
    # Returns true or throws an exception
    def validate
      node = @page.parser
      error_node   and raise Errors::UnexpectedContentError.new(node, error_node.content.to_s.strip)
      content_node  or raise Errors::UnexpectedContentError.new(node, "Cannot find question content")
      form_node     or raise Errors::UnexpectedContentError.new(node, "Cannot find question form")
      question_node or raise Errors::UnexpectedContentError.new(node, "Cannot find question node")

      true
    end


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
