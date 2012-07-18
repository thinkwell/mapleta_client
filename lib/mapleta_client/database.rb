module Maple::MapleTA

  attr_accessor :database_config, :database

  def self.database(*args)
    args = [self.database_config] if args.empty?
    Maple::MapleTA::Database::Connection.new(*args)
  end
end
