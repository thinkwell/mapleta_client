module Maple::MapleTA

  attr_accessor :database_config, :database

  def self.database(*args)
    args = [self.database_config] if args.empty?
    begin
      Maple::MapleTA::Database::Connection.new(*args)
    rescue PG::Error => e
      raise Errors::DatabaseError.new(nil, e)
    end
  end
end
