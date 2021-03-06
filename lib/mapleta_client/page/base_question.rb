module Maple::MapleTA
module Page

  class BaseQuestion < Base
    include Form
    attr_reader :clickable_image_base_url

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

    def correct_answer_check_present?
      @correct_answer_check_present ||= content_node.xpath('.//img[contains(@src, "correct_small.png")]').length > 0
    end

    def time_remaining
      if @time_remaining.nil?
        content_node.xpath('.//script[contains(text(), "remainingTime")]').each do |node|
          if node.text =~ /var remainingTime\s*=\s*(\d+)/
            @time_remaining = $1.to_i
            break
          end
        end
        @time_remaining = -1 if @time_remaining.nil?
      end

      @time_remaining == -1 ? nil : @time_remaining
    end

    def current_grade
      return @current_grade if @current_grade
      if @current_grade = content_node.at_css('div#currentGrade')
        @current_grade = @current_grade.content.gsub('Current Grade:', '').strip
      end
    end

    ###
    # These methods return html snippets intended to be inserted directly in
    # a html page
    #

    def html
      # inner_xhtml
      html = question_node.children.map { |x| x.to_xhtml }.join
      html.gsub!('This question accepts formulas in Maple syntax.', '')
      html.gsub!('This question accepts numbers or formulas.', '')
      use_secure_image_proxy html
    end
    alias :question_html :html


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
      @question_node ||= form_node.at_css("div.questionstyle")
    end


    #
    ###




    ###
    # These methods apply different fixes to the html returned from Maple
    #

    # Shortcut for applying all html fixes
    def fix_html
      fix_preview_links
      fix_plot_links
      fix_help_links
      remove_preview_links
      remove_plot_links
      fix_help_links
      fix_equation_entry_mode_links
      fix_equation_editor
      fix_text_equation_null_value
      remove_equation_editor_label
    end


    def fix_text_equation_null_value
      form_node.xpath('.//input[contains(@name, "maple[ans.") and @value="NULL"]').each do |node|
        node['value'] = ""
      end
    end

    def remove_plot_links
      form_node.xpath('.//font[text()="Plot"]').each do |node|
        if node.next_sibling && node.next_sibling.text? && node.next_sibling.content =~ /\|/
          node.next_sibling.remove
        end
        node.remove
      end
      form_node.xpath('.//img[contains(@src, "/ploton.gif")]').each do |node|
        if node.next_element && node.next_element.name == 'span' && node.next_element.content =~ /^\s*/ && node.next_element.content.length < 3
          node.next_element.remove
        end
        node.remove
      end
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
        node.remove_attribute('onmouseover')
        node.remove_attribute('onmouseout')
        node['class'] = 'change-equation-entry-mode inline-icon'
        5.times { node.previous_element.remove if node.previous_element.name() == 'br' }
        node.content = title
      end
    end


    def fix_equation_editor
      equation_editors.each do |node|
        create_equation_editor_node(node)
        node.remove
      end
    end

    def remove_equation_editor_label
      form_node.xpath('.//span[text()="Equation Editor" and @class="mathedit"]').each do |node|
        tr_node = node.parent.parent rescue nil
        if tr_node && tr_node.node_name == 'tr'
          tr_node.remove
        end
      end
    end

    def remove_preview_links
        form_node.xpath('.//a[text()="Preview" or @title="Preview"]').each do |node|
          if node.previous_sibling && node.previous_sibling.text? && node.previous_sibling.content =~ /\|/
            node.previous_sibling.remove
          end
        node.remove
      end
    end

    def fix_help_links
      form_node.xpath('.//a[contains(@href, "PartialGradingHelp")]').remove
      form_node.xpath('.//a[contains(@onclick, "PartialGradingHelp")]').remove
      form_node.xpath('.//a[contains(@onclick, "gateway.question.NumberHelp")]').remove
      form_node.xpath('.//a[contains(@onclick, "gateway.question.UnitsHelp")]').remove
      form_node.xpath('.//a[contains(@href, "getHelp")]').each do |node|
        next_node = node.next
        if next_node && next_node.text? && next_node.text =~ /^\s*\|\s*$/
          next_node.remove
        end
        node.remove
      end
    end

    def create_equation_editor_node(node)
      container_node = @page.parser.create_element 'div'
      container_node['class'] = 'eq-editor'
      container_node['style'] = 'display: none;'
      container_node['name'] = node['name'];
      #container_node.inner_html = node.inner_html
      node.parent.add_child(container_node)

      if n = node.at_xpath('.//param[@name="mathml"]')
        mathMLUnescaped = n['value']
        Rails.logger.info "base_question : mathml : #{mathMLUnescaped}"
        content_mathml = URI.unescape(mathMLUnescaped)
        Rails.logger.info "base_question : content mathml : #{content_mathml}"
        presentation_mathml = BaseQuestion.convert_to_presentation_mathml(content_mathml)
        Rails.logger.info "base_question : presentation mathml : #{presentation_mathml}"
        @mathML = encode_math_ml(presentation_mathml)
        Rails.logger.info "base_question : mathml encoded : #{@mathML}"
      end

      mathML_node = @page.parser.create_element 'input'
      mathML_node['type'] = 'hidden'
      mathML_node['id'] = node['name']+'.mathML'
      mathML_node['value'] = @mathML.nil? ? '' : @mathML
      mathML_node['name'] = node['name']+'.mathML'
      node.parent.add_child(mathML_node)
      container_node
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

    def remove_preview_links
      form_node.xpath('.//a[text()="Preview" or @title="Preview"]').each do |node|
        if node.previous_sibling && node.previous_sibling.text? && node.previous_sibling.content =~ /\|/
          node.previous_sibling.remove
        end
        node.remove
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

    def remove_plot_links
      form_node.xpath('.//font[text()="Plot"]').each do |node|
        if node.next_sibling && node.next_sibling.text? && node.next_sibling.content =~ /\|/
          node.next_sibling.remove
        end
        node.remove
      end
    end

    def fix_help_links
      form_node.xpath('.//a[contains(@href, "PartialGradingHelp")]').remove
      form_node.xpath('.//a[contains(@onclick, "PartialGradingHelp")]').remove
      form_node.xpath('.//a[contains(@onclick, "gateway.question.NumberHelp")]').remove
      form_node.xpath('.//a[contains(@onclick, "gateway.question.UnitsHelp")]').remove
      form_node.xpath('.//a[contains(@href, "getHelp")]').each do |node|
        next_node = node.next
        if next_node && next_node.text? && next_node.text =~ /^\s*\|\s*$/
          next_node.remove
        end
        node.remove
      end
    end

    def self.convert_to_presentation_mathml(content_mathml)
      return "" if content_mathml.blank?
      file_path = File.expand_path("mmlctop2_0.xsl", File.dirname(__FILE__))
      doc   = Nokogiri::XML::Document.parse(content_mathml)
      doc.xpath("//*").each { |node| node.default_namespace="http://www.w3.org/1998/Math/MathML"}
      xslt  = Nokogiri::XSLT(File.read(file_path))
      xslt.transform(doc).to_s
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
    end

  private

    def mandatory_fixes
      # Move hidden fields out of the question node
      # This prevents duplicate hidden nodes when using question_html and hidden_fields_html
      question_node.xpath(".//input[@type='hidden']").each {|node| node.parent = form_node}
    end


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


    def encode_math_ml(math_ml)

      # Multiple replacement version of String.tr
      strtr = lambda do |str, replace_pairs|
        keys = replace_pairs.keys
        values = replace_pairs.values
        str.gsub(
          /(#{keys.map{|a| Regexp.quote(a) }.join( ')|(' )})/
        ) { |match| values[keys.index(match)] }
      end

      strtr.call(math_ml, {
        ' ' => '%20',
        '+' => '%2B',
        '&' => '%26',
        '<' => '%3C',
        '=' => '%3D',
        '>' => '%3E',
        '?' => '%3F',
      })
    end

    def equation_editors
      form_node.xpath('.//applet[contains(@code, "mathEditor") or contains(@code, "SimpleEditorApplet")]')
    end

    def change_equation_entry_mode_links
      form_node.xpath('.//a[contains(@class, "change-equation-entry-mode")]')
    end

    def text_editors(node)
      node.xpath('.//input[contains(@name, "maple[ans.")]')
    end
  end

end
end
