module Maple::MapleTA
  def self.init_db(*args)
    @database_connection.close if @database_connection
    @database_connection = Maple::MapleTA::Database::Connection.new(*args)
  end

  def self.database
    raise "Maple Database connection isn't initialized.  Did you forget to call Maple::MapleTA.init_db?" unless @database_connection
    @database_connection
  end
end
