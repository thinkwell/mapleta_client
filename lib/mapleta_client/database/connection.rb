require 'pg'

module Maple::MapleTA
  module Database
    class Connection < ::PG::Connection
      include Macros::Assignment
      include Macros::User
      include Macros::TestRecord
      include Macros::Classes

    end
  end
end
