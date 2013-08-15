require 'spec_helper'

module Maple::MapleTA
module Database::Macros
  describe Assignment do

    before(:all) do
      @settings = RSpec.configuration.maple_settings
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

    describe "create_assignment" do
      before(:each) do
        @questions = @database_connection.questions_for_assignment_class(@settings[:class_id])
        question = @questions.first
        question.weighting = 3
        @assignment = Maple::MapleTA::Assignment.new(:name => "test assignment", :class_id => @mapleta_class.id,
                                     :questions => [question], :reworkable => false, :printable => true)
        result = @database_connection.create_assignment(@assignment)
        @new_assignment_id = result[0]
        @new_assignment_class_id = result[1]
      end

      after(:each) do
        @database_connection.delete_assignment(@new_assignment_class_id)
      end

      describe "update_assignment" do
        before(:each) do
          @assignment.name = "test assignment edited"
          @assignment.questions = [@questions[1]]
          @assignment.reworkable = true
          @assignment.printable = false
          @assignment.id = @new_assignment_id
          @database_connection.edit_assignment(@assignment)
        end

        it "should update the assignment" do
          assignment = @database_connection.assignment(@mapleta_class.id)
          assignment.should_not be_nil
          assignment['name'].should == "test assignment edited"
        end

        it "should update the assignment_question_groups" do
          assignment_question_groups = @database_connection.assignment_question_groups(@new_assignment_id)
          assignment_question_groups.count.should == 1
          assignment_question_groups.first['name'].should == @questions[1].name
        end

        it "should update the assignment_class" do
          assignment_class = @database_connection.assignment_class(@mapleta_class.id)
          assignment_class.should_not be_nil
          assignment_class['assignmentid'].should == "#{@new_assignment_id}"
          assignment_class['name'].should == "test assignment edited"
        end

        it "should update the assignment_policy" do
          assignment_class = @database_connection.assignment_class(@mapleta_class.id)
          assignment_policy = @database_connection.assignment_policy(assignment_class['id'])
          assignment_policy.should_not be_nil
          assignment_policy['reworkable'].should == 't'
          assignment_policy['printable'].should == 'f'
        end

        it "should retrieve assignment via web service" do
          assignment = @connection.ws.assignment(Maple::MapleTA::Assignment.new(:id => @new_assignment_class_id, :class_id => @mapleta_class.id))
          assignment.should_not be_nil
        end
      end

      it "should create a new assignment" do
        @new_assignment_id.should_not be_nil

        assignment = @database_connection.assignment(@mapleta_class.id)
        assignment.should_not be_nil
        assignment['name'].should == "test assignment"
      end

      it "should create the assignment_question_group for each question" do
        assignment_question_groups = @database_connection.assignment_question_groups(@new_assignment_id)
        assignment_question_groups.count.should == 1
        assignment_question_groups.first['name'].should == @questions.first.name
        assignment_question_groups.first['order_id'].should == "0"
        assignment_question_groups.first['weighting'].should == "3"
      end

      it "should create the assignment_class" do
        assignment_class = @database_connection.assignment_class(@mapleta_class.id)
        assignment_class.should_not be_nil
        assignment_class['assignmentid'].should == "#{@new_assignment_id}"
        assignment_class['name'].should == "test assignment"
      end

      it "should create the assignment_policy" do
        assignment_class = @database_connection.assignment_class(@mapleta_class.id)
        assignment_policy = @database_connection.assignment_policy(assignment_class['id'])
        assignment_policy.should_not be_nil
        assignment_policy['reworkable'].should == 'f'
        assignment_policy['printable'].should == 't'
      end
    end

    describe "copy_assignment_to_class" do

      before(:each) do
        assignment_class = @database_connection.exec("SELECT * FROM assignment_class limit 1").first
        @new_assignment_class_id = @database_connection.copy_assignment_to_class(assignment_class['id'], @mapleta_class.id)
      end

      after(:each) do
        @database_connection.delete_assignment(@new_assignment_class_id)
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
