require 'spec_helper'

module Maple::MapleTA
module Database::Macros
  describe Assignment do

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

    describe "copy_assignment_to_class" do

      before(:each) do
        assignment_class = @database_connection.exec("SELECT * FROM assignment_class limit 1").first
        @new_assignment_class_id = @database_connection.copy_assignment_to_class(assignment_class['id'], @mapleta_class.id)
      end

      after(:each) do
        @database_connection.delete_assignment_class(@mapleta_class.id)
        @database_connection.delete_assignment(@mapleta_class.id)
      end

      it "should create a new assignment_class" do
        @new_assignment_class_id.should_not be_nil
      end
    end

    #it "set_assignment_max_attempts" do
    #  @database_connection.set_assignment_max_attempts(@mapleta_class.id, 3)
    #  @database_connection.assignment_max_attempts(@mapleta_class.id).should == 3
    #
    #  @database_connection.set_assignment_max_attempts(@mapleta_class.id, nil)
    #  @database_connection.assignment_max_attempts(@mapleta_class.id).should be_false
    #end

  end
end
end
