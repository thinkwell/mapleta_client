module Maple::MapleTA
module Page

  # TODO: Refactor this module to better support pages with more than one
  # form (such as the proctor authorization page)

  module Form

    module ClassMethods

      # Modifies all form fields in the given node so that name="bar"
      # becomes name="foo[bar]"
      def update_form_param_names(node, new_name, old_name=nil)
        node.xpath('.//input[@name] | .//select[@name] | .//textarea[@name]').each do |node|
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
            node['name'] = "#{new_name}[#{field}]#{extra if extra}"
          end
        end
      end
    end

    module InstanceMethods

      def form_name
        'edu_form'
      end


      def form_action
        action = form_node.attr('action')
        if !(action =~ /^\//) && !(action =~ /^\w+:/)
          action = "#{orig_base_url}#{action}"
        end
        action
      end


      def form_node
        @form_node ||= content_node.at_xpath(".//form[@name='#{form_name}']")
      end


      def form_params
        mechanize_form.fields.inject({}) do |p, field|
          p[$1] = field.value if field.name =~ /^#{Regexp.escape(form_param_name.to_s)}\[([^\[]+)\]/
          p
        end
      end


      def mechanize_form
        @mechanize_form ||= Mechanize::Form.new(form_node, @page.mech, @page)
      end


      def hidden_fields
        @hidden_fields ||= form_node.xpath(".//input[@type='hidden']")
      end


      def hidden_fields_html
        hidden_fields.to_xhtml
      end


      # Modifies all form fields so that name="bar" becomes name="foo[bar]"
      def form_param_name=(name)
        return if @form_param_name.to_s == name.to_s
        self.class.update_form_param_names(form_node, name, @form_param_name)
        @form_param_name = name
      end




      def form_name_for(name)
        if form_param_name && form_param_name.to_s != ""
          if name =~ /^([^\[\]]+)(.*)$/
            field = $1
            extra = $2
            name = "#{form_param_name}[#{field}]#{extra if extra}"
          end
        end
        name
      end

    end

    def self.included(base)
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods

      attr_reader :form_param_name
      base.default_option :form_param_name, :maple
    end

  end

end
end
