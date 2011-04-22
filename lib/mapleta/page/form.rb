module Maple::MapleTA
module Page

  module Form

    module ClassMethods
    end

    module InstanceMethods

      def form_action
        form_node.attr('action')
      end


      def form_node
        @form_node || content_node.at_xpath(".//form[@name='edu_form']")
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

      attr_accessor :form_param_name
      base.default_option :form_param_name, :maple
    end

  end

end
end
