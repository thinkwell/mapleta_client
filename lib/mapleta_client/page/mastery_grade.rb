module Maple::MapleTA
module Page

  class MasteryGrade < Base
    include Form

    # Returns true if the given page looks like a page this class can parse
    def self.detect(page)
      return false unless form = page.parser.at_xpath('.//form[@name="edu_form"]')
      return false unless form['action'] =~ /sequentialTest\.QuestionSheet|gradeProctoredTest/
      page.parser.xpath('.//th[text()="Topic"]').length != 0 && page.parser.xpath('.//th[text()="% of Requirements"]').length != 0
    end



    def state
      :grade
    end


    def just_graded?(maple_request_params)
      return false unless maple_request_params.is_a?(Hash)

      maple_request_params[:actionID] == 'finishsession'
    end


    def results_node
      # First time this page is displayed, the results node looks like this
      @results_node ||= content_node.at_xpath('.//center/table')

      # Every other time, the results node is here:
      @results_node ||= content_node.at_xpath('.//table[@align="center"]//tr[@align="center"]//table')
    end


    def results_html
      results_node.to_xhtml
    end
    alias :html :results_html


    def fix_html
      remove_empty_cells
    end


    def remove_empty_cells
      results_node.xpath('.//td[@width="5"]').each do |td|
        td.remove if td.children.length == 0
      end
    end



    private

    def validate
      node = @page.parser
      content_node or raise Errors::UnexpectedContentError.new(node, "Cannot find content")
      results_node or raise Errors::UnexpectedContentError.new(node, "Cannot find results")
    end

  end

end
end
