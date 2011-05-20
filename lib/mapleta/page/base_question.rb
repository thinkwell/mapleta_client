module Maple::MapleTA
module Page

  class BaseQuestion < Base
    include Form
    attr_reader :clickable_image_base_url


    def initialize(page, opts={})
      super

      # Move hidden fields out of the question node
      # This prevents duplicate hidden nodes when using question_html and hidden_fields_html
      question_node.xpath(".//input[@type='hidden']").each {|node| node.parent = form_node}
    end




    def title
      # TODO: Can question title ever be something other than "Question \d"?
      "Question #{number}"
    end


    def equation_entry_mode
      return @equation_entry_mode if @equation_entry_mode

      if form_node.xpath('.//applet[@code="applets.twodeeeditor.mathEditor"]').length > 0
        @equation_entry_mode = :symbol
      else
        @equation_entry_mode = :text
      end
    end


    def feedback_allowed?
      return @feedback_allowed unless @feedback_allowed == nil
      @feedback_allowed = content_node.xpath('.//a[@href="javascript:doInSessionFeedback()"]').length > 0
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

    #
    ###




    ###
    # These methods apply different fixes to the html returned from Maple
    #

    # Shortcut for applying all html fixes
    def fix_html
      fix_equation_entry_mode_links
      fix_equation_editor
      fix_preview_links
      fix_plot_links
      fix_help_links
    end


    def fix_equation_entry_mode_links
      form_node.xpath('.//a[text()="Change Entry Style" or text()="Change Math Entry Mode" or @title="Change entry mode"]').each do |node|
        case equation_entry_mode
        when :symbol
          node['href'] = "#text"
          title = "Switch to text input"
        when :text
          node['href'] = "#symbol"
          title = "Switch to Equation Editor"
        end
        node['class'] = 'change-equation-entry-mode'
        if node.xpath('./img').length > 0
          node['class'] += " inline-icon"
          node['title'] = title
          node.remove_attribute 'onmouseout'
          node.remove_attribute 'onmouseover'
        end
        node.content = title
      end
    end


    def fix_equation_editor
      form_node.xpath('.//applet[contains(@code, "mathEditor")]').each do |node|
        node.xpath('.//param[@name="helpUrl"]').remove
        unless node.xpath('.//param[@name="toolbar"]').length > 0
          new_node = @page.parser.create_element 'param'
          new_node['name'] = 'toolbar'
          new_node['value'] = 'true'
          node.add_child(new_node)
        end
        if n = node.at_xpath('.//param[@name="mathmlHeight"]')
          n['value'] = '180'
        end
        if n = node.at_xpath('.//param[@name="tooltip"]')
          n['value'] = 'Equation editor'
        end
      end
    end


    def fix_preview_links
      form_node.xpath('.//a[text()="Preview" or @title="Preview"]').each do |node|
        if node['href'] =~ /previewFormula\([^,]*getElementsByName\('([^']+)'\)[^,]*,.*'([^\)]+)'\)/
          node['href'] = "##{$1}"
          node['data-maple-action'] = $2
          node['class'] = 'preview'
          if node.xpath('./img').length > 0
            node.content = "Preview"
            node['class'] += " inline-icon"
            node.remove_attribute 'onmouseout'
            node.remove_attribute 'onmouseover'
          end
        end
      end
    end


    def fix_plot_links
      form_node.xpath('.//a[text()="Plot" or @title="Plot"]').each do |node|
        if (node['href'] =~ /popupMaplePlot\('(.+)'\s*,\s*document.getElementsByName\('([^']+)'\)[^']*,\s*'(.*)'\s*,\s*'(.*)'\s*,\s*'(.*)'\)/ ||
            node['href'] =~ /popupMaplePlot\('(.+)'\s*,\s*document\['([^']+)'\]\.getResponse\(\)\s*,\s*'(.*)'\s*,\s*'(.*)'\s*,\s*'(.*)'\)/)
          node['href'] = "##{$2}"
          node['class'] = 'plot'
          node['data-plot'] = $1
          node['data-type'] = $3
          node['data-libname'] = $4
          node['data-driver'] = $5
          if node.xpath('./img').length > 0
            node.content = "Plot"
            node['class'] += " inline-icon"
            node.remove_attribute 'onmouseout'
            node.remove_attribute 'onmouseover'
          end
        end
      end

      # Remove disabled inline plot icons
      form_node.xpath('.//img[contains(@src, "ploton.gif")]').remove
    end


    def fix_help_links
      form_node.xpath('.//a[contains(@href, "PartialGradingHelp")]').remove
      form_node.xpath('.//a[contains(@href, "getHelp")]').each do |node|
        next_node = node.next
        if next_node && next_node.text? && next_node.text =~ /^\s*\|\s*$/
          next_node.remove
        end
        node.remove
      end
    end


    # Removes "vertical-align: -\d+px;" inline style that causes images to appear
    # lower than surrounding text.
    # NOTE: Maple adds this to center equation images (such as fractions) with
    # the surrounding inline text.  It is better to set the img.vertical-align
    # style to baseline than to remove the vertical-align inline styles with this
    # method.
    def fix_image_position
      content_node.xpath('.//span[img and @style]').each do |node|
        node['style'] = node['style'].gsub(/vertical-align: -?\d+px;/, '')
      end
    end


    #
    ###


    def clickable_image_base_url=(url)
      @clickable_image_base_url = url
      @page.parser.xpath('//applet[@code="applets.clickableImage.ClickableImageApplet"]/param[@name="baseURL"]').each do |node|
        node['value'] = url
      end
    end


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


  end

end
end