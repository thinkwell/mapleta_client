module Maple::MapleTA
module Page

  class Question < BaseQuestion

    # Returns true if the given page looks like a page this class can parse
    def self.detect(page)
      !page.parser.at_css('input[@type="hidden"][name="questionId"]').nil?
    end

    def fix_html
      fix_equation_entry_mode_links
      fix_equation_editor
      fix_text_equation_null_value
      fix_image_position
      fix_preview_links
      fix_plot_links
      fix_help_links
      remove_preview_links
      remove_plot_links
      remove_equation_editor_label
    end

    def content_node
      @content_node ||= @page.parser.at_css('div[@class="questionstyle"]')
    end

    def form_node
      content_node
    end

    def question_node
      content_node
    end

    def validate
      node = @page.parser
      content_node or raise Errors::UnexpectedContentError.new(node, "Cannot find page content")
      true
    end
  end

end
end
