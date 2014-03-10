require 'pg'

module Maple::MapleTA
  class << self
    attr_accessor :database_config

    def database_timezone
      @database_timezone ||= ActiveSupport::TimeZone.create('UTC')
    end

    def database_timezone=(timezone)
      @database_timezone = ActiveSupport::TimeZone.create timezone
    end

    def database_connection
      @database_connection ||=
        begin
          connection = Database::Connection.new database_config
          connection.exec("SET TIMEZONE='#{database_timezone.name}'")
          connection
        end
    end
  end
end
