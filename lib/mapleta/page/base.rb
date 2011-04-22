require 'active_support/inflector'

module Maple::MapleTA
module Page

  class Base
    attr_reader :page
    attr_accessor :base_url

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
      @default_options ||= {}
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
      @content_node || @page.parser.at_css('div.content')
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
      @page.parser.xpath('//td[@background]').each {|node| node['background'] = Connection.abs_url_for(node['background'], uri)}
    end

  private

    def validate
      true
    end

  end

end
end
