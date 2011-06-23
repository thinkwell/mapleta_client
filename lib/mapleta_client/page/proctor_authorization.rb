module Maple::MapleTA
module Page

  class ProctorAuthorization < Base
    include Form

    # Returns true if the given page looks like a page this class can parse
    def self.detect(page)
      !!page.parser.at_xpath('.//form[@name="AuthorizeActionForm"]')
    end


    def form_name
      'AuthorizeActionForm'
    end


    def authorize_form_node
      @authorize_form_node ||= content_node.at_xpath(".//form[@name='#{form_name}'][1]")
    end


    def authorize_hidden_fields
      @authorize_hidden_fields ||= authorize_form_node.xpath(".//input[@type='hidden']")
    end


    def authorize_hidden_fields_html
      authorize_hidden_fields.to_xhtml
    end


    def authorize_form_action
      authorize_form_node.attr('action')
    end


    def remote_authorize_form_node
      @remote_authorize_form_node ||= content_node.at_xpath(".//form[@name='#{form_name}'][2]")
    end


    def remote_authorize_hidden_fields
      @remote_authorize_hidden_fields ||= remote_authorize_form_node.xpath(".//input[@type='hidden']")
    end


    def remote_authorize_hidden_fields_html
      remote_authorize_hidden_fields.to_xhtml
    end


    def remote_authorize_form_action
      remote_authorize_form_node.attr('action')
    end


    def message_node
      @message_node ||= authorize_form_node.at_xpath('./table/tr/td')
    end

    def message
      message_node.text
    end


    def student_name
      authorize_form_node.at_xpath(".//input[@name='#{form_name_for 'studentName'}']")['value'] rescue nil
    end


    def student_id
      authorize_form_node.at_xpath(".//input[@name='#{form_name_for 'studentID'}']")['value'] rescue nil
    end


    def auth_type
      authorize_form_node.at_xpath(".//input[@name='#{form_name_for 'authType'}']").parent.text.strip rescue nil
    end


    def assignment_name
      authorize_form_node.at_xpath(".//input[@name='#{form_name_for 'asgnName'}']")['value'] rescue nil
    end


    def class_name
      authorize_form_node.at_xpath(".//input[@name='#{form_name_for 'className'}']")['value'] rescue nil
    end


    # TODO: Refactor!  This includes copy and paste code from form.rb
    def form_param_name=(name)
      return if @form_param_name.to_s == name.to_s
      [authorize_form_node, remote_authorize_form_node].each do |form_node|
        self.class.update_form_param_names(form_node, name, @form_param_name)
      end
      @form_param_name = name
    end




    private

    def validate
      node = @page.parser
      content_node or raise Errors::UnexpectedContentError.new(node, "Cannot find content node")
      message_node or raise Errors::UnexpectedContentError.new(node, "Cannot find message node")

      true
    end

  end

end
end
