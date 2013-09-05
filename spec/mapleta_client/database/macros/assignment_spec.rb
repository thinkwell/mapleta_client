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
      @questions = @database_connection.questions_for_assignment_class(@settings[:class_id])
      assignment_question_group_map_1 = Maple::MapleTA::AssignmentQuestionGroupMap.new(:questionid => @questions[0].id, :question_uid => @questions[0].uid)
      assignment_question_group_map_2 = Maple::MapleTA::AssignmentQuestionGroupMap.new(:questionid => @questions[1].id, :question_uid => @questions[1].uid)
      assignment_question_group_1 = Maple::MapleTA::AssignmentQuestionGroup.new(:name => @questions[0].name, :assignment_question_group_maps => [assignment_question_group_map_1], :weighting => 3)
      assignment_question_group_2 = Maple::MapleTA::AssignmentQuestionGroup.new(:name => @questions[1].name, :assignment_question_group_maps => [assignment_question_group_map_2])
      @assignment = Maple::MapleTA::Assignment.new(:name => "test assignment", :class_id => @mapleta_class.id,
                      :assignment_question_groups => [assignment_question_group_1, assignment_question_group_2],
                      :reworkable => false, :printable => true, :scramble => 1, :reuse_algorithmic_variables => true,
                      :targeted => true, :final_feedback_date => '', :start => '2012-08-22 23:15:30'.to_time, :end => '2013-08-22 23:15:30'.to_time)
    end

    after(:each) do
      @database_connection.delete_class(@mapleta_class.id)
    end

    describe "create_assignment for MODE_UNPROCTORED_TEST" do
      before(:each) do
        @assignment.mode = Maple::MapleTA::Assignment::MODE_UNPROCTORED_TEST
        @assignment.max_attempts = nil
        result = @database_connection.create_assignment(@assignment)
        @new_assignment_id = result[0]
        @new_assignment_class_id = result[1]
      end

      after(:each) do
        @database_connection.delete_assignment(@new_assignment_class_id)
      end

      it "should create the assignment_policy with the MODE_UNPROCTORED_TEST options" do
        assignment_class = @database_connection.assignment_class(@mapleta_class.id)
        assignment_policy = @database_connection.assignment_policy(assignment_class['id'])
        assignment_policy.should_not be_nil
        assignment_policy['reuse_algorithmic_variables'].should == 't'
        assignment_policy['targeted'].should == 't'
        assignment_policy['reworkable'].should == 'f'
        assignment_policy['printable'].should == 't'
        assignment_policy['scramble'].should == '1'
      end

      it "should not create the assignment_advanced_policies" do
        assignment_advanced_policies = @database_connection.assignment_advanced_policies(@new_assignment_class_id)
        assignment_advanced_policies.count.should == 0
      end


    end

    describe "create_assignment for MODE_PROCTORED_TEST" do
      before(:each) do
        @assignment.mode = Maple::MapleTA::Assignment::MODE_PROCTORED_TEST
        @assignment.max_attempts = 5
        result = @database_connection.create_assignment(@assignment)
        @new_assignment_id = result[0]
        @new_assignment_class_id = result[1]
      end

      after(:each) do
        @database_connection.delete_assignment(@new_assignment_class_id)
      end

      it "should create the assignment_question_group and map for each question" do
        assignment_question_groups = @database_connection.assignment_question_groups(@new_assignment_class_id).to_a
        assignment_question_groups.count.should == 2
        assignment_question_groups.first.name.should == @questions[1].name
        assignment_question_groups.first.order_id.should == 1
        assignment_question_groups.first.weighting.should == 1
        assignment_question_groups.last.name.should == @questions[0].name
        assignment_question_groups.last.order_id.should == 0
        assignment_question_groups.last.weighting.should == 3

        assignment_question_group_maps = @database_connection.assignment_question_group_maps(@new_assignment_class_id)
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

      it "should create the assignment_advanced_policies for max_attempt" do
        assignment_advanced_policies = @database_connection.assignment_advanced_policies(@new_assignment_class_id)
        assignment_advanced_policies.should_not be_nil
        assignment_advanced_policies.count.should == 1
        assignment_advanced_policies[0]['keyword'].should == @assignment.max_attempts.to_s
      end

      it "should create the assignment_policy with the MODE_PROCTORED_TEST options" do
        assignment_class = @database_connection.assignment_class(@mapleta_class.id)
        assignment_policy = @database_connection.assignment_policy(assignment_class['id'])
        assignment_policy.should_not be_nil
        assignment_policy['reuse_algorithmic_variables'].should == 'f'
        assignment_policy['targeted'].should == 'f'
        assignment_policy['reworkable'].should == 'f'
        assignment_policy['printable'].should == 'f'
        assignment_policy['scramble'].should == '0'
        assignment_policy['start_authorization_required'].should == 't'
      end

      it "should be retrievable by assignment_obj" do
        assignment = @database_connection.assignment_obj(@new_assignment_class_id)
        assignment.should_not be_nil
        assignment.id.should == @new_assignment_class_id
        assignment.assignment_question_groups.count.should == @assignment.assignment_question_groups.count
        assignment.assignment_question_groups[0].assignment_question_group_maps[0].name.should_not be_nil
        assignment.assignment_question_groups[0].is_question.should be_true
        assignment.max_attempts.should == @assignment.max_attempts
        assignment.printable.should be_false
        assignment.start.should == '2012-08-22 23:15:30'.to_time
        assignment.end.should == '2013-08-22 23:15:30'.to_time
      end

      it "should create a new assignment" do
        @new_assignment_id.should_not be_nil

        assignment = @database_connection.assignment(@mapleta_class.id)
        assignment.should_not be_nil
        assignment['name'].should == "test assignment"
      end

      describe "update_assignment" do
        before(:each) do
          @assignment.name = "test assignment edited"
          @assignment.max_attempts = nil
          @assignment.start = '2012-09-22 23:15:30'
          @assignment.end = '2013-09-22 23:15:30'
          assignment_question_group_map_3 = Maple::MapleTA::AssignmentQuestionGroupMap.new(:questionid => @questions[2].id, :question_uid => @questions[2].uid)
          assignment_question_group_3 = Maple::MapleTA::AssignmentQuestionGroup.new(:name => @questions[2].name, :assignment_question_group_maps => [assignment_question_group_map_3])
          @assignment.assignment_question_groups = [@assignment.assignment_question_groups[0], assignment_question_group_3]
          @assignment.reworkable = true
          @assignment.printable = false
          @assignment.id = @new_assignment_class_id
          @database_connection.edit_assignment(@assignment)
        end

        it "should update the assignment" do
          assignment = @database_connection.assignment(@mapleta_class.id)
          assignment.should_not be_nil
          assignment['name'].should == "test assignment edited"
        end

        it "should update the assignment_question_groups and maps" do
          assignment_question_groups = @database_connection.assignment_question_groups(@new_assignment_class_id).to_a
          assignment_question_groups.count.should == 2
          assignment_question_groups.first.name.should == @questions[2].name
          assignment_question_groups.last.name.should == @questions[0].name

          assignment_question_group_maps = @database_connection.assignment_question_group_maps(@new_assignment_class_id).to_a
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
          assignment_policy['reuse_algorithmic_variables'].should == 'f'
          assignment_policy['targeted'].should == 'f'
          assignment_policy['reworkable'].should == 't'
          assignment_policy['printable'].should == 'f'
          assignment_policy['scramble'].should == '0'
        end

        it "should update the assignment_advanced_policy" do
          assignment_advanced_policies = @database_connection.assignment_advanced_policies(@new_assignment_class_id)
          assignment_advanced_policies.count.should == 0
        end

        it "should retrieve assignment via web service" do
          assignment = @connection.ws.assignment(Maple::MapleTA::Assignment.new(:id => @new_assignment_class_id, :class_id => @mapleta_class.id))
          assignment.should_not be_nil
        end

        it "should be retrievable by assignment_obj" do
          assignment = @database_connection.assignment_obj(@new_assignment_class_id)
          assignment.should_not be_nil
          assignment.id.should == @new_assignment_class_id
          assignment.assignment_question_groups.count.should == @assignment.assignment_question_groups.count
          assignment.assignment_question_groups[0].assignment_question_group_maps[0].name.should_not be_nil
          assignment.assignment_question_groups[0].is_question.should be_true
          assignment.max_attempts.should == @assignment.max_attempts
          assignment.printable.should be_false
          assignment.start.should == '2012-09-22 23:15:30'.to_time
          assignment.end.should == '2013-09-22 23:15:30'.to_time
        end

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
