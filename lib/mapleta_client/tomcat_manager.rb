module Maple::MapleTA
  def self.restart_maple(opts={})
    opts = {
      :manager_url => 'http://localhost:8080/manager',
      :user => 'tomcat',
      :password => 'tomcat',
      :app => 'mapleta'
    }.merge(opts.symbolize_keys)

    begin
      uri = URI.parse("#{opts[:manager_url]}/reload?path=#{opts[:app]}")
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Get.new(uri.request_uri)
      request.basic_auth(opts[:user], opts[:password]) if opts[:user] && opts[:password]
      response = http.request(request)
      unless response.is_a?(Net::HTTPSuccess)
        raise Errors::TomcatManagerError.new("Error restarting Maple Tomcat: #{response.body}")
      end
    rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, Errno::ECONNREFUSED, EOFError,
           Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
      raise Errors::TomcatManagerError.new("Error restarting Maple Tomcat: #{e.message}", e)
    end
  end
end
