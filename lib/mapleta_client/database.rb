require 'pg'

module Maple::MapleTA

  def self.database_config
    @database_config
  end

  def self.database_config=(config)
    @database_config = config
  end

  def self.database_timezone
    @database_timezone ||= ActiveSupport::TimeZone.create('UTC')
  end

  def self.database_timezone=(tz)
    tz = ActiveSupport::TimeZone.create(tz) unless tz.is_a?(ActiveSupport::TimeZone)
    @database_timezone = tz
  end

  def self.establish_database_connection(*args)
    self.database_config = args unless args.empty?
    begin
      remove_database_connection
      opts = self.database_config.is_a?(Array) ? self.database_config : [self.database_config]
      @database_connection = Maple::MapleTA::Database::Connection.new(*opts)
      @database_connection.exec("SET TIMEZONE='#{self.database_timezone.name}'")
      @database_connection
    rescue PG::Error => e
      raise Errors::DatabaseError.new(nil, e)
    end
  end

  def self.database_connection
    # Remove finished or broken connections
    begin
      if @database_connection && (@database_connection.finished? || @database_connection.status != PG::CONNECTION_OK)
        remove_database_connection
      end
    rescue PG::Error
      @database_connection = nil
    end

    self.establish_database_connection unless @database_connection
    @database_connection
  end

  def self.remove_database_connection
    (@database_connection.close rescue nil) if @database_connection
    @database_connection = nil
  end
end
