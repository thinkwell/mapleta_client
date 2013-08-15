module Maple::MapleTA
  class MockConnection
    def initialize(opts={})
    end

    def connect
      @connected = true
    end

    def disconnect
      @connected = false
    end

    def launcher(action, params={})
    end

    def connected?
      @connected
    end

    def ws
      @ws ||= WebService.new(self)
    end

    def launcher_params(action)
      {}
    end

    def session
      nil
    end

    def use_math_editor
      @use_math_editor
    end

    def fetch_response(uri, method=:get, post_body=nil)
    end

    def fetch_page(url, params={}, request_method=:get)
    end

    def fetch_api(method, params={}, reconnect_if_expired=true)
    end

    def fetch_api_page(method, params={}, request_method=:get, reconnect_if_expired=true)
    end

    def api_signature
      ts = Time.now.to_i * 1000
      {'timestamp' => ts, 'signature' => 'foobar'}
    end

    def agent
    end

    def ws_url
    end

    def abs_url_for(url)
    end

    def self.abs_url_for(url, base_url)
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

    protected

    def fetch_api_response(method, params={}, format=:xml)
    end

    def parse_api_response(response)
    end

    def cookies
      {}
    end

    def use_math_editor=(val)
      return @use_math_editor = nil if val == nil || val.to_s == ""
      @use_math_editor = val.to_s == 'true' ? true : false
    end
  end
end
