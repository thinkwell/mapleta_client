require 'active_support/inflector'

module Maple::MapleTA
module Page

  class Base
    attr_reader :page, :base_url, :applet_archives_url

    def initialize(page, opts={})
      @page = page
      raise "Must pass Mechanize::Page as :page (got: #{@page.class})" unless @page.is_a?(Mechanize::Page)

      validate

      self.class.default_options.merge(opts).each do |key, val|
        if self.respond_to?("#{key}")
          if respond_to?("#{key}=")
            self.send("#{key}=", val)
          else
            self.instance_variable_set("@#{key}", val)
          end
        end
      end
    end


    def self.default_options
      @default_options ||= superclass.respond_to?(:default_options) ? superclass.default_options.dup : {}
    end

    def self.default_option(key, val)
      default_options[key] = val
    end


    def type
      self.class.to_s.split('::').last.underscore
    end



    ###
    # These methods return html snippets intended to be inserted directly in
    # a html page

    def html
      # inner_xhtml
      content_node.children.map { |x| x.to_xhtml }.join
    end

    #
    ###


    ###
    # These methods return nokogiri nodes at various important points in the
    # question document
    #

    def content_node
      @content_node ||= @page.parser.at_css('div.content')
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
      @page.parser.xpath('//td[@background]').each {|node| node['background'] = Connection.abs_url_for(node['background'], uri)}
      @page.parser.xpath('//applet/param[@name="image" or @name="imageURL"]').each {|node| node['value'] = Connection.abs_url_for(node['value'], uri)}
    end


    def applet_archives_url=(url)
      @applet_archives_url = url

      @page.parser.xpath('//applet[@archive]').each do |node|
        node['archive'] = node['archive'].split(',').map do |u|
          u =~ /([^\/]+)$/ ? "#{url}#{$1}" : u
        end.join(', ')
      end

      # Replace codebase with archive="applets.jar"
      # using our modified signed applets.jar file hosted with canvas
      @page.parser.xpath('//applet[@codebase]').each do |node|
        node.remove_attribute('codebase')
        unless node.xpath('.//param[@name="codebase_lookup"]').length > 0
          new_node = @page.parser.create_element 'param'
          new_node['name'] = 'codebase_lookup'
          new_node['value'] = 'false'
          node.add_child(new_node)
        end
        next if node['archive'] && node['archive'] =~ /applets\.jar/

        node['archive'] = "#{node['archive']}," if node['archive'] && !(node['archive'] =~ /^\s*$|,$/)
        node['archive'] = "#{node['archive']}#{url}applets.jar"
      end
    end


    def fix_html
      # Subclasses should override this if they need to perform fixes on the
      # Maple html
    end


    def orig_base_url
      return @orig_base_url if @orig_base_url

      uri = @page.uri
      if node = @page.parser.at_xpath('.//base[@href]')
        uri = node['href']
      end
      uri = URI.parse(uri) unless uri.is_a?(URI)
      @orig_base_url = uri.path.gsub(/[^\/]*$/, '')
    end

  private

    def validate
      true
    end

  end

end
end
