require 'spec_helper'

module Maple::MapleTA
  module Database::Macros
    describe Classes do
      let(:connection) { Maple::MapleTA::Connection.new RSpec.configuration.maple_settings }
      let(:database)   { RSpec.configuration.database_connection }
      let(:mapleta_class) {
        result = database.exec <<-SQL
         INSERT INTO classes (name, dirname) VALUES ('Example class', 'dirname?')
         RETURNING cid
        SQL

        double 'Class', id: result.values.join.to_i
      }

      it "deletes the created class" do
        database.delete_class(mapleta_class.id)
        pending
      end
    end
  end
end
