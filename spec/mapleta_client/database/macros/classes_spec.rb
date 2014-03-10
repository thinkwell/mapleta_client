require 'spec_helper'

module Maple::MapleTA
  module Database::Macros
    describe Classes do
      let(:database)      { RSpec.configuration.database_connection }
      let(:role_id)       { database.dataset[:roles].insert(id: 1, role: 'student') }
      let(:mapleta_class) { create :class }
      let(:user_class)    { create :user_class, classid: mapleta_class.id, roleid: role_id }

      before do
        mapleta_class.save
        user_class.save
      end

      describe 'deleteting a class' do
        it "deletes the class" do
          expect {
            database.delete_class mapleta_class.id
          }.to change{ Maple::MapleTA::Orm::Class.count }.by(-1)
        end

        it "deletes the user class" do
          expect {
            database.delete_class mapleta_class.id
          }.to change{ Maple::MapleTA::Orm::Class.count }.by(-1)
        end
      end
    end
  end
end
