require 'spec_helper'

module Maple::MapleTA
  module Database::Macros
    describe Assignment do
      let(:settings)        { RSpec.configuration.maple_settings }
      let(:database)        { RSpec.configuration.database_connection }
      let(:mapleta_class)   { create :class }
      let(:questions)       { [ create(:question, :name => 'Example question',   :author => mapleta_class.id) ] }
      let(:other_questions) { [ create(:question, :name => 'Example question 2', :author => mapleta_class.id) ] }
      let(:assignment)      {
        build(:assignment, :name => "test assignment",
              :class_id => mapleta_class.id,
              :questions => questions)
      }

      describe 'creating an assignment' do
        before(:each) do
          @assignment = database.create_assignment assignment
        end

        describe "creating an assignment" do
          it "should create a new assignment" do
            assignment = @assignment.reload
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
            assignment.assignment_classes.should have(1).item

            assignment_class = assignment.assignment_classes.first
            assignment_class.assignment.should == @assignment
            assignment_class.name.should == "test assignment"
          end

          it "should create the assignment policy" do
            assignment_class  = assignment.assignment_classes.first
            assignment_policy = assignment_class.assignment_policy
            assignment_policy.should_not be_nil
            assignment_policy.reworkable.should be false
            assignment_policy.printable.should be true
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
            assignment.assignment_classes.should have(1).item

            assignment_class = assignment.assignment_classes.first
            assignment_class.assignment.should == @assignment
            assignment_class.name.should == "test assignment edited"
          end

          it "should update the assignment_policy" do
            database.edit_assignment assignment

            assignment_class  = assignment.assignment_classes.first
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
          it { expect{ assignment.assignment_classes_dataset.destroy }.to change{ Orm::AssignmentClass.count }.by(-1) }
          it { expect{ assignment.assignment_classes_dataset.destroy }.to change{ Orm::AssignmentPolicy.count }.by(-1) }
        end

        describe 'max attempts' do
          let(:assignment_class)  { Orm::AssignmentClass.first }

          it "set_assignment_max_attempts" do
            database.set_assignment_max_attempts assignment_class.id, 3
            database.assignment_max_attempts(assignment_class.id).should == 3

            database.set_assignment_max_attempts assignment_class.id, nil
            database.assignment_max_attempts(assignment_class.id).should be_false
          end
        end
      end

      describe "copy assignment to class" do
        let(:existing_class)        { create :class }
        let(:new_class)             { create :class }
        let(:assignment_class_copy) { database.copy_assignment_to_class(assignment_class.id, new_class.id) }
        let(:assignment_class)      { Orm::AssignmentClass.first }

        before do
          3.times do |num|
            assignment = create(:assignment, :classid => existing_class.id)
            assignment_class = create :assignment_class, :class_id => existing_class.id, :assignment_id => assignment.id

            3.times { 
              question = create(:question, :author => existing_class.id)
              group = Orm::AssignmentQuestionGroup.create(:assignment_id => assignment.id, :order_id => 0)

              3.times {
                map = Orm::AssignmentQuestionGroupMap.
                create(:question_id => question.id, :group_id => group.id)
              }
            }
            
            Orm::AssignmentPolicy.create(:assignment_class_id => assignment_class.id)
            Orm::AdvancedPolicy.create(:assignment_class_id => assignment_class.id, :and_id => 1, :or_id => 1, :keyword => 1, :assignment_id => assignment.id, :has => 1)
          end
        end

        it { assignment_class_copy.class_id.should == new_class.id }
        it { assignment_class_copy.reload.assignment.class_id.should == new_class.id }
        it { expect { assignment_class_copy }.to change{ Orm::AssignmentClass.count }.by 1 }
        it { expect { assignment_class_copy }.to change{ Orm::Assignment.count }.by 1 }
        it { expect { assignment_class_copy }.to change{ Orm::AssignmentPolicy.count }.by 1 }
        it { expect { assignment_class_copy }.to change{ Orm::AdvancedPolicy.count }.by 1 }
        it { expect { assignment_class_copy }.to change{ Orm::AssignmentQuestionGroup.count }.by 3 }
        it { expect { assignment_class_copy }.to change{ Orm::AssignmentQuestionGroupMap.count }.by 9 }
        it { expect { assignment_class_copy }.not_to change{ Orm::Question.count } }
      end
    end
  end
end
