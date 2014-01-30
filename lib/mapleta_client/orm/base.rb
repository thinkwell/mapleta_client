module Maple::MapleTA::Orm

  def self.connection_settings
    @connection_settings
  end

  def self.connection_settings=(settings)
    @connection_settings ||= settings
  end

  def self.included(base)
    base.establish_connection connection_settings if base.respond_to? 'establish_connection'
  end

end