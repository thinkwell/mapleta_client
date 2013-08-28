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
        assignment_question_group_map_1 = Maple::MapleTA::AssignmentQuestionGroupMap.new(:questionid => @questions[0].id, :question_uid => @questions[0].uid)
        assignment_question_group_map_2 = Maple::MapleTA::AssignmentQuestionGroupMap.new(:questionid => @questions[1].id, :question_uid => @questions[1].uid)
        assignment_question_group_1 = Maple::MapleTA::AssignmentQuestionGroup.new(:name => @questions[0].name, :assignment_question_group_maps => [assignment_question_group_map_1], :weighting => 3)
        assignment_question_group_2 = Maple::MapleTA::AssignmentQuestionGroup.new(:name => @questions[1].name, :assignment_question_group_maps => [assignment_question_group_map_2])
        @assignment = Maple::MapleTA::Assignment.new(:name => "test assignment", :class_id => @mapleta_class.id,
                                     :assignment_question_groups => [assignment_question_group_1, assignment_question_group_2],
                                     :reworkable => false, :printable => true, :scramble => 1)
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
          assignment_question_group_map_3 = Maple::MapleTA::AssignmentQuestionGroupMap.new(:questionid => @questions[2].id, :question_uid => @questions[2].uid)
          assignment_question_group_3 = Maple::MapleTA::AssignmentQuestionGroup.new(:name => @questions[2].name, :assignment_question_group_maps => [assignment_question_group_map_3])
          @assignment.assignment_question_groups = [@assignment.assignment_question_groups[0], assignment_question_group_3]
          @assignment.reworkable = true
          @assignment.printable = false
          @assignment.id = @new_assignment_class_id
          @assignment.assignmentid = @new_assignment_id
          @database_connection.edit_assignment(@assignment)
        end

        it "should update the assignment" do
          assignment = @database_connection.assignment(@mapleta_class.id)
          assignment.should_not be_nil
          assignment['name'].should == "test assignment edited"
        end

        it "should update the assignment_question_groups and maps" do
          assignment_question_groups = @database_connection.assignment_question_groups(@new_assignment_id).to_a
          assignment_question_groups.count.should == 2
          assignment_question_groups.first.name.should == @questions[2].name
          assignment_question_groups.last.name.should == @questions[0].name

          assignment_question_group_maps = @database_connection.assignment_question_group_maps(@new_assignment_id).to_a
          assignment_question_group_maps.count.should == 2
          assignment_question_group_maps.first.questionid.should == @questions[2].id
          assignment_question_group_maps.first.groupid.should == assignment_question_groups.first.id
          assignment_question_group_maps.first.order_id.should == 0
          assignment_question_group_maps.last.questionid.should == @questions[0].id
          assignment_question_group_maps.last.groupid.should == assignment_question_groups.last.id
          assignment_question_group_maps.last.order_id.should == 0
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

      it "should create the assignment_question_group and map for each question" do
        assignment_question_groups = @database_connection.assignment_question_groups(@new_assignment_id).to_a
        assignment_question_groups.count.should == 2
        assignment_question_groups.first.name.should == @questions[1].name
        assignment_question_groups.first.order_id.should == 1
        assignment_question_groups.first.weighting.should == 1
        assignment_question_groups.last.name.should == @questions[0].name
        assignment_question_groups.last.order_id.should == 0
        assignment_question_groups.last.weighting.should == 3

        assignment_question_group_maps = @database_connection.assignment_question_group_maps(@new_assignment_id)
        assignment_question_group_maps.count.should == 2
        assignment_question_group_maps.first.questionid.should == @questions[1].id
        assignment_question_group_maps.first.groupid.should == assignment_question_groups.first.id
        assignment_question_group_maps.first.order_id.should == 0
        assignment_question_group_maps.last.questionid.should == @questions[0].id
        assignment_question_group_maps.last.groupid.should == assignment_question_groups.last.id
        assignment_question_group_maps.last.order_id.should == 0
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
        assignment_policy['scramble'].should == '1'
      end

      it "should be retrievable by assignment_obj" do
        assignment = @database_connection.assignment_obj(@new_assignment_class_id)
        assignment.should_not be_nil
        assignment.assignmentid.should == @new_assignment_id
        assignment.id.should == @new_assignment_class_id
        assignment.assignment_question_groups.count.should == @assignment.assignment_question_groups.count
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
