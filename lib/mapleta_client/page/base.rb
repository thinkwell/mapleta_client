require 'active_support/inflector'

module Maple::MapleTA
module Page

  class Base
    attr_reader :page, :base_url, :applet_archives_url

    def initialize(page, opts={})
      @page = page
      raise "Must pass Mechanize::Page as :page (got: #{@page.class})" unless @page.is_a?(Mechanize::Page)

      validate
      mandatory_fixes

      opts = (Page.default_options || {}).merge(self.class.default_options).merge(opts)
      opts.each do |key, val|
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


    def pretty_print_node(node)
      xsl = Nokogiri::XSLT <<-EOXSL
        <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
          <xsl:output method="xml" encoding="ISO-8859-1"/>
          <xsl:param name="indent-increment" select="' '"/>

          <xsl:template name="newline">
            <xsl:text disable-output-escaping="yes">
            </xsl:text>
          </xsl:template>

          <xsl:template match="comment() | processing-instruction()">
            <xsl:param name="indent" select="''"/>
            <xsl:call-template name="newline"/>
            <xsl:value-of select="$indent"/>
            <xsl:copy />
          </xsl:template>

          <xsl:template match="text()">
            <xsl:param name="indent" select="''"/>
            <xsl:call-template name="newline"/>
            <xsl:value-of select="$indent"/>
            <xsl:value-of select="normalize-space(.)"/>
          </xsl:template>

          <xsl:template match="text()[normalize-space(.)='']"/>

          <xsl:template match="*">
            <xsl:param name="indent" select="''"/>
            <xsl:call-template name="newline"/>
            <xsl:value-of select="$indent"/>
            <xsl:choose>
              <xsl:when test="count(child::*) > 0">
                <xsl:copy>
                  <xsl:copy-of select="@*"/>
                  <xsl:apply-templates select="*|text()">
                    <xsl:with-param name="indent" select="concat ($indent, $indent-increment)"/>
                  </xsl:apply-templates>
                  <xsl:call-template name="newline"/>
                  <xsl:value-of select="$indent"/>
                </xsl:copy>
              </xsl:when>
              <xsl:otherwise>
                <xsl:copy-of select="."/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:template>
        </xsl:stylesheet>
      EOXSL

      xsl.apply_to(node).to_s
    end


    def script_html
      html = ''
      html << "#{base_url_script_node.to_html}\n" if base_url_script_node
      html << "#{math_jax_script_node.to_html}\n" if math_jax_script_node
      html
    end

    def math_jax_script_html
      html = ''
      html << "#{math_jax_script_node.to_html}\n" if math_jax_script_node
      html
    end

    def base_url_script_node
      return @base_url_script_node if @base_url_script_node
      return nil if @base_url_script_node == false
      @base_url_script_node = @page.parser.xpath('//script').detect(false) do |node|
        node.content.include?('function getBaseURL()')
      end
    end

    def math_jax_script_node
      return @math_jax_script_node if @math_jax_script_node
      return nil if @math_jax_script_node == false
      @math_jax_script_node = @page.parser.xpath('//script').detect(false) do |node|
        node['src'] and node['src'].include?('MathJax.js')
      end
    end


    private

    def validate
      true
    end

    def mandatory_fixes
      # Intentionally blank, subclasses can override
    end

    def add_class(root_node, selector, class_name, type = :xpath)
      return unless [:css, :xpath].include?(type)
      root_node.send(type, selector).each do |node|
        node['class'] = (node['class'] ? node['class'] + ' ' : '') + class_name
      end
    end

  end

end
end
