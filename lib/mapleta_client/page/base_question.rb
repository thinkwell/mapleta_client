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
      fix_text_equation_null_value
      remove_equation_editor_label
    end


    def fix_text_equation_null_value
      form_node.xpath('.//input[contains(@name, "maple[ans.") and @value="NULL"]').each do |node|
        node['value'] = ""
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
