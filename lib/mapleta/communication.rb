module Maple::MapleTA
  module Communication

    module ClassMethods
      def abs_url_for(url, base_url)
        if url =~ /^\//
          base_uri = base_url.is_a?(URI) ? base_url : URI.parse(base_url)
          prefix = "#{base_uri.scheme}://#{base_uri.host}"
          prefix << ":#{base_uri.port}" unless base_uri.port == base_uri.default_port
          url = "#{prefix}#{url}"
        elsif !(url =~ /^\w+:/)
          url = "#{base_url.to_s}/#{url}"
        end

        url
      end
    end

    module InstanceMethods

      def fetch_response(uri, method=:get, post_body=nil)
        uri = URI.parse(abs_url_for(uri)) if uri.is_a?(String)
        request = method==:post ? Net::HTTP::Post.new(uri.request_uri) : Net::HTTP::Get.new(uri.request_uri)
        request['Cookie'] = cookies.collect {|key, val| "#{key}=#{val}"}.join('; ')
        if method == :post
          request.body = post_body if post_body
        end
        yield(request) if block_given?

        begin
          Net::HTTP.new(uri.host, uri.port).start do |http|
            http.use_ssl = true if uri.scheme == 'https'
            http.request(request)
          end
        rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, Errno::ECONNREFUSED, EOFError,
               Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
          raise Errors::NetworkError, e
        end
      end


      def fetch_page(url, params={}, request_method=:get)
        url = abs_url_for(url)
        params = fix_mechanize_params(params)

        begin
          case request_method
          when :post
            page = agent.post(url, params)
          else
            page = agent.get(:url => url, :params => params)
          end

          # Check for a redirection page
          redirects = 0
          while (redirects < 5 &&
              page.parser.xpath('.//title').text() == 'Redirector' &&
              page.parser.xpath('.//body[@onload="doSubmit();"]').length > 0 &&
              page.forms.first)
            page = page.forms.first.submit
            redirects += 1
          end

        rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, Errno::ECONNREFUSED, EOFError,
               Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
          raise Errors::NetworkError, e
        end

        page
      end


      def fetch_api(method, params={}, reconnect_if_expired=true)
        begin
          parse_api_response(fetch_api_response(method, params, :xml))
        rescue Errors::SessionExpiredError => e
          if connected? && reconnect_if_expired
            disconnect
            connect
            fetch_api(method, params, false)
          end
        end
      end


      def fetch_api_page(method, params={}, request_method=:get)
        params = api_signature.merge(params)

        page = fetch_page("#{ws_url}/#{method}", params, request_method)

        # Check for an API response (instead of an HTML page)
        if response_element = (page.parser.at_xpath('/response') || page.parser.at_xpath('/html/body/response'))
          err = response_element.at_xpath('./status/message').content rescue "Failure launching Maple T.A."
          raise Errors::UnexpectedContentError.new(page.parser, err)
        end

        page
      end



      def api_signature
        ts = Time.now.to_i * 1000
        {'timestamp' => ts, 'signature' => signature(ts)}
      end


      def agent
        @agent ||= Mechanize.new.tap do |agent|
          uri = URI.parse(base_url)
          cookies.each do |key, val|
            cookie = Mechanize::Cookie.new(key, val)
            cookie.domain = uri.host
            cookie.path = uri.path
            agent.cookie_jar.add(uri, cookie)
          end

          agent.user_agent = user_agent if user_agent
        end
      end


      def ws_url
        "#{base_url}/ws"
      end


      def abs_url_for(url)
        @base_uri ||= (base_url && URI.parse(base_url))
        self.class.abs_url_for(url, @base_uri)
      end


    protected

      def fetch_api_response(method, params={}, format=:xml)
        params = api_signature.merge(params)

        fetch_response(URI.parse("#{ws_url}/#{method}"), :post) do |request|
          case format
          when :xml
            request.body = params.to_xml(:root => 'Request', :skip_types => true)
            request['Content-Type'] = 'text/xml'
          when :form
            request.set_form_data(params)
          end
        end
      end


      def parse_api_response(response)
        # Convert the response into a Hash
        # We should test for content_type == 'text/xml' here, but some methods return valid
        # XML as 'text/html', so try everything
        data = Hash.from_xml(response.body) rescue nil
        data = data && data['Response'] || data

        # Raise some exceptions if we can't understand the response
        if response.code.to_i != 200
          err = data['status']['message'] rescue "#{response.code}: #{response.message}"
        elsif !data.is_a?(Hash)
          err = "Cannot parse response"
        elsif data['status'] && !data['status'].has_key?('code')
          err = data['status']['message'] rescue "Cannot read status code"
        end
        raise Errors::InvalidResponseError.new(response, "An error occurred while fetching data from the server.\n#{err}") if err

        if data['status'] && data['status']['code'].to_i == 1
          if data['status']['message'] == "Unauthorized access to Maple TA Assignment Service." && self.respond_to?(:session) && session
            raise Errors::SessionExpiredError.new(session)
          else
            err = data['status']['message'] rescue "Request returned failure status"
            raise Errors::MapleTAError, err
          end
        end

        data
      end


      def cookies
        cookies = {}
        cookies['JSESSIONID'] = "#{session}" if self.respond_to?(:session) && session != nil
        cookies['useMathEditor'] = "#{use_math_editor}" if self.respond_to?(:use_math_editor) && use_math_editor != nil
        cookies
      end


      def use_math_editor=(val)
        return @use_math_editor = nil if val == nil || val.to_s == ""
        @use_math_editor = val.to_sym == :true ? true : false
      end


    private
      def signature(ts)
        ::ActiveSupport::Base64.encode64(Digest::MD5.digest("#{ts}#{secret}")).gsub("\n",'')
      end

      # Mechanize unescapes HTML entities such as &minus; in string form data.
      # This causes a problem with MathML, which expects entities such as
      # &minus; instead of "-".  This function uses a custom object to
      # represent MathML data, thus preventing Mechanize from unescaping it.
      #
      # See mechanize/lib/mechanize/form/field.rb
      def fix_mechanize_params(params)
        params.inject({}) do |memo, (key, val)|
          if val =~ /^<(xml|math)/
            memo[key] = RawString.new(val)
          else
            memo[key] = val
          end
          memo
        end
      end

    end



    def self.included(base)
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
      require 'active_support'
      require 'active_support/core_ext/hash/conversions'
      require 'digest/md5'
      require 'net/http'
      require 'net/https'
      require 'uri'
      require 'mechanize'

      attr_accessor :secret, :base_url, :user_agent, :use_math_editor
    end

  end
end
