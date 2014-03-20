require 'spec_helper'

module Maple::MapleTA
  module Database::Macros
    describe Assignment do
      let(:settings)        { RSpec.configuration.maple_settings }
      let(:database)        { RSpec.configuration.database_connection }
      let(:mapleta_class)   { create :class }
      let(:questions)       { [ create(:question, name: 'Example question',   author: mapleta_class.id) ] }
      let(:other_questions) { [ create(:question, name: 'Example question 2', author: mapleta_class.id) ] }
      let(:assignment)      {
        build(:assignment, name: "test assignment",
              class_id: mapleta_class.id,
              questions: questions)
      }

      before(:each) do
        @assignment = database.create_assignment assignment
      end

      describe "creating an assignment" do
        it "should create a new assignment" do
          @assignment.should_not be_nil

          assignment = database.assignment mapleta_class.id
          assignment.should_not be_nil
          assignment.name.should == "test assignment"
        end

        it "should create the assignment question group for each question" do
          assignment_question_groups = @assignment.assignment_question_groups
          assignment_question_groups.should have(1).item
          assignment_question_groups.first.name.should == 'Example question'
        end

        it "creates the assignment question group map" do
          pending
        end

        it "should create the assignment class" do
          assignment_class = database.assignment_class mapleta_class.id
          assignment_class.should_not be_nil
          assignment_class.assignment.should == @assignment
          assignment_class.name.should == "test assignment"
        end

        it "should create the assignment policy" do
          assignment_class  = database.assignment_class mapleta_class.id
          assignment_policy = database.assignment_policy assignment_class.id
          assignment_policy.should_not be_nil
          assignment_policy['reworkable'].should be false
          assignment_policy['printable'].should be true
        end
      end

      describe "updating an assignment and dependent records" do
        before(:each) do
          assignment.name       = "test assignment edited"
          assignment.questions  = other_questions
          assignment.reworkable = true
          assignment.printable  = false
          assignment.id         = @assignment.id
        end

        it "should update the assignment" do
          assignment = database.edit_assignment @assignment
          assignment.name.should == "test assignment edited"
        end

        it "should update the assignment_question_groups" do
          assignment = database.edit_assignment @assignment
          assignment_question_groups = assignment.assignment_question_groups
          assignment_question_groups.should have(1).item
          assignment_question_groups.first.name.should == 'Example question 2'
        end

        it "should update the assignment_class" do
          assignment = database.edit_assignment @assignment
          assignment_class = assignment.assignment_class
          assignment_class.should_not be_nil
          assignment_class.assignment.should == @assignment
          assignment_class.name.should == "test assignment edited"
        end

        it "should update the assignment_policy" do
          database.edit_assignment assignment
          assignment_class  = assignment.assignment_class
          assignment_policy = assignment_class.assignment_policy
          assignment_policy.reworkable.should be true
          assignment_policy.printable.should be false
        end
      end

      describe 'removing an assignment' do
        it { expect{ assignment.destroy }.to change{ Orm::Assignment.count }.by(-1) }
        it { expect{ assignment.destroy }.to change{ Orm::AssignmentClass.count }.by(-1) }
        it { expect{ assignment.destroy }.to change{ Orm::AssignmentQuestionGroup.count }.by(-1) }
        it { expect{ assignment.destroy }.to change{ Orm::AssignmentQuestionGroupMap.count }.by(-1) }
      end

      describe 'removing an assignmnet class' do
        it { expect{ assignment.assignment_class.destroy }.to change{ Orm::AssignmentClass.count }.by(-1) }
        it { expect{ assignment.assignment_class.destroy }.to change{ Orm::AssignmentPolicy.count }.by(-1) }
      end

      describe "copy_assignment_to_class" do
        let(:assignment_class)  { Orm::AssignmentClass.first }
        let(:new_mapleta_class) { create :class }
        let(:assignment_copy)   { database.copy_assignment_to_class assignment_class.id, new_mapleta_class.id }

        it { expect { assignment_copy }.to change{ Orm::Assignment.count }.by 1 }
        it { expect { assignment_copy }.to change{ Orm::AssignmentClass.count }.by 1 }
        it { expect { assignment_copy }.to change{ Orm::AssignmentPolicy.count }.by 1 }
        it { expect { assignment_copy }.to change{ Orm::AssignmentQuestionGroup.count }.by 1 }
        it { expect { assignment_copy }.to change{ Orm::AssignmentQuestionGroupMap.count }.by 1 }
      end

      describe 'max attempts' do
        it "set_assignment_max_attempts" do
          pending "Aparently not implemented correctly"
          database.set_assignment_max_attempts mapleta_class.id, 3
          database.assignment_max_attempts(mapleta_class.id).should == 3

          database.set_assignment_max_attempts mapleta_class.id, nil
          database.assignment_max_attempts(mapleta_class.id).should be_false
        end
      end
    end
  end
end
