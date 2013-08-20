require 'spec_helper'

module Maple::MapleTA
module Database::Macros
  describe Classes do

    before(:all) do
      @connection = spec_maple_connection
      @database_connection = Maple::MapleTA.database_connection
      @connection.connect
    end

    before(:each) do
      @mapleta_class = @connection.ws.create_class("my-test-class")
    end

    after(:each) do
      @database_connection.delete_class(@mapleta_class.id)
    end

    it "deletes the created class" do
      @connection.ws.clazz(@mapleta_class.id).should_not be_nil
      @database_connection.delete_class(@mapleta_class.id)
      @connection.ws.clazz(@mapleta_class.id).should be_nil
    end


  end
end
end
