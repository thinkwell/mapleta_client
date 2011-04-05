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
        uri = URI.parse(uri) if uri.is_a?(String)
        request = method==:post ? Net::HTTP::Post.new(uri.request_uri) : Net::HTTP::Get.new(uri.request_uri)
        request['Cookie'] = "JSESSIONID=#{session}" if self.respond_to?(:session)
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

        begin
          case request_method
          when :post
            agent.post(url, params)
          else
            agent.get(:url => url, :params => params)
          end
        rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, Errno::ECONNREFUSED, EOFError,
               Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
          raise Errors::NetworkError, e
        end
      end


      def fetch_api(method, params={})
        parse_api_response(fetch_api_response(method, params, :xml))
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
          if self.respond_to?(:session)
            uri = URI.parse(base_url)
            cookie = Mechanize::Cookie.new('JSESSIONID', "#{session}")
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
          err = data['status']['message'] rescue "Request returned failure status"
          raise Errors::MapleTAError, err
        end

        data
      end


    private
      def signature(ts)
        ::ActiveSupport::Base64.encode64(Digest::MD5.digest("#{ts}#{secret}")).gsub("\n",'')
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

      attr_accessor :secret, :base_url, :user_agent
    end

  end
end
