require 'spec_helper'

module Maple::MapleTA
  module Database::Macros
    describe Classes do
      let(:connection) { Maple::MapleTA::Connection.new RSpec.configuration.maple_settings }
      let(:database)   { RSpec.configuration.database_connection }
      let(:mapleta_class) {
        cid = database.dataset[:classes].insert(name: 'Example class', dirname: 'dirname?')
        double 'Class', id: cid, save: true
      }

      let(:user_class) {
        id = database.dataset[:user_classes].insert(
          classid: mapleta_class.id,
          roleid: database.dataset[:roles].insert(id: 1, role: 'student')
        )
        double 'UserClass', id: id,  save: true
      }

      before do
        mapleta_class.save
        user_class.save
      end

      describe 'deleteting a class' do
        it "deletes the class" do
          expect {
            database.delete_class mapleta_class.id
          }.to change{ database.dataset[:classes].count }.by(-1)
        end

        it "deletes the user class" do
          expect {
            database.delete_class mapleta_class.id
          }.to change{ database.dataset[:user_classes].count }.by(-1)
        end
      end
    end
  end
end
