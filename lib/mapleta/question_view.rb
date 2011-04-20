module Maple::MapleTA
  class QuestionView
    attr_accessor :form_param_name, :base_url, :fix_equation_entry_mode_links, :fix_preview_links
    attr_reader :page


    def initialize(page, opts={})
      @page = page
      raise "Must pass Mechanize::Page as :page (got: #{@page.class})" unless @page.is_a?(Mechanize::Page)
      validate

      {
        :form_param_name => :question,
      }.merge(opts).each do |key, val|
        if self.respond_to?("#{key}")
          if respond_to?("#{key}=")
            self.send("#{key}=", val)
          else
            self.instance_variable_set("@#{key}", val)
          end
        end
      end

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


    def form_action
      form_node.attr('action')
    end


    # Returns the entry style used for input, either :text or :symbol
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


    def hidden_fields_html
      hidden_fields.to_xhtml
    end


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


    def content_node
      @content_node || @page.parser.at_css('div.content')
    end


    def form_node
      @form_node || content_node.at_xpath(".//form[@name='edu_form']")
    end


    def question_node
      #@question_node ||= form_node.at_xpath("./div[@style='margin: 10px']/table[last()]/tr/td[2]")
      @question_node ||= form_node.at_css("div.questionstyle")
    end


    def hidden_fields
      @hidden_fields ||= form_node.xpath(".//input[@type='hidden']")
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



    # Modifies all relative URL to use absolute URLs, using this URL
    # as the base URL
    def base_url=(url)
      @base_url = url
      uri = URI.parse(@base_url)

      @page.parser.xpath('//*[@src]').each {|node| node['src'] = Connection.abs_url_for(node['src'], uri)}
      @page.parser.xpath('//*[@href]').each {|node| node['href'] = Connection.abs_url_for(node['href'], uri)}
      @page.parser.xpath('//applet[@codebase]').each {|node| node['codebase'] = Connection.abs_url_for(node['codebase'], uri)}
      @page.parser.xpath('//applet/param[@name="image"]').each {|node| node['value'] = Connection.abs_url_for(node['value'], uri)}
      @page.parser.xpath('//applet[@archive]').each do |node|
        node['archive'] = node['archive'].split(',').map do |u|
          Connection.abs_url_for(u.strip, uri)
        end.join(', ')
      end
    end


    # Modifies all form fields so that name="bar" becomes name="foo[bar]"
    def form_param_name=(name)
      return if @form_param_name.to_s == name.to_s

      old_name = @form_param_name
      @form_param_name = name


      form_node.xpath('.//input[@name] | .//select[@name] | .//textarea[@name]').each do |node|
        # This Regexp matches:
        #   1) field_name
        #   2) old_param_name[field_name]
        # and replaces with:
        #   form_param_name[field_name]
        #
        # It also allows for any number bracketted groups such as:
        #   3) field_name[foo][bar]
        #   4) old_param_name[field_name][foo][bar]
        # will be replaced with:
        #   form_param_name[field_name][foo][bar]
        #
        if node['name'] =~ /^(?:#{Regexp.escape(old_name.to_s)}\[([^\[\]]+)\]|([^\[\]]+))(\[.*)?$/
          field = $1 || $2
          extra = $3
          node['name'] = "#{form_param_name}[#{field}]#{extra if extra}"
        end
      end
    end


    def fix_equation_entry_mode_links=(bool)
      return unless bool

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


    def fix_preview_links=(bool)
      return unless bool

      form_node.xpath('.//a[text()="Preview"]').each do |node|
        if node['href'] =~ /previewFormula\([^,]*getElementsByName\('([^']+)'\)[^,]*,.*'([^\)]+)'\)/
          node['href'] = "##{$1}"
          node['class'] = 'preview'
          node['maple_action'] = $2
        end
      end
    end



  private

    # Validates that the mechanize page contains a Maple T.A. question,
    # Returns true or throws an exception
    def validate
      node = @page.parser
      begin
        error_node   and raise Errors::UnexpectedContentError.new(node, error_node.content.to_s.strip)
        content_node  or raise Errors::UnexpectedContentError.new(node, "Cannot find question content")
        form_node     or raise Errors::UnexpectedContentError.new(node, "Cannot find question form")
        question_node or raise Errors::UnexpectedContentError.new(node, "Cannot find question node")
      rescue Errors::UnexpectedContentError => e
        if Rails && Rails.logger
          Rails.logger.error "Error parsing Maple T.A. question: #{e.message}"
          Rails.logger.debug "Maple T.A. response: #{e.node.to_html}"
        end
        raise e
      end

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
