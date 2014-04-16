require 'spec_helper'

module Maple::MapleTA
  module Orm
    describe AssignmentClass do

      let(:mapleta_class)     { create :class }
      let(:mapleta_class_2)   { create :class, :name => "Class 2"}
      let(:question)          { create(:question, :author => mapleta_class.id) }
      let(:assignment)        { create(:assignment, :name => "test assignment", :class_id => mapleta_class.id) }
      let(:assignment_question_group)     {
        create(:assignment_question_group,
               :assignmentid => assignment.id,
               :order_id => 1)
      }
      let(:assignment_question_group_map) {
        create(:assignment_question_group_map,
               :groupid => assignment_question_group.id,
               :questionid => question.id)
      }
      let(:assignment_class)  {
        create(:assignment_class,
               :class_id => mapleta_class.id,
               :name => assignment.name,
               :assignmentid => assignment.id)
      }
      let(:assignment_policy) {
        create(:assignment_policy,
               :assignment_class_id => assignment_class.id,
               :start_time => Time.now,
               :end_time => Time.now+1.month)
      }

      before(:each) do
        mapleta_class.reload
        mapleta_class_2.reload
        assignment.reload
        assignment_class.reload
        assignment_policy.reload
        assignment_question_group.reload
        assignment_question_group_map.reload
      end


      describe "creating an assignment_class including parent and all associations" do

        it "should create a new assignment" do
          expect(assignment).to_not be_nil
        end

        it "should create a new assignment_class" do
          expect(assignment_class).to_not be_nil
          expect(assignment_class.assignmentid).to eq(assignment.id)
          expect(assignment_class.name.should).to eq("test assignment")
        end

        it "should create a new assignment_policy" do
          expect(assignment_policy).to_not be_nil
        end

        it "should create new assignment_question_group" do
          expect(assignment_question_group).to_not be_nil
          expect(assignment_question_group.assignmentid).to eq(assignment.id)
          expect(assignment.assignment_question_groups.count).to eq(1)
        end

        it "should create new assignment_question_group_map" do
          expect(assignment_question_group_map).to_not be_nil
          expect(assignment.assignment_question_groups.first.assignment_question_group_maps.count).to eq(1)
        end

      end


      describe "copying an assignment class" do

        context "copy an assignment to the same class without options" do

          let(:acc) { assignment_class.copy }

          it "should copy assignment_class into the same class including new associated records" do
            expect(acc).to_not be_nil
            expect(acc.assignment.id).to_not eq(assignment.id)
            aqg = acc.assignment.assignment_question_groups
            expect(aqg.first.id).to_not eq(assignment_question_group.id)
            expect(aqg.first.assignment_question_group_maps.first.id).to_not eq(assignment_question_group_map.id)
            expect(acc.assignment_policy).to_not be_nil
            expect(acc.class_id).to eq(acc.assignment.class_id)
            expect(acc.class_id).to eq(mapleta_class.id)
          end

          it "should copy the start and end dates from the original assignment" do
            expect(acc.assignment_policy.start_time).to eq(assignment_policy.start_time)
            expect(acc.assignment_policy.end_time).to eq(assignment_policy.end_time)
          end

          it "should create the correct number of new records" do
            acc.reload
            expect(Orm::Class.count).to eq(2)
            expect(Orm::Assignment.count).to eq(2)
            expect(Orm::AssignmentClass.count.should).to eq(2)
            expect(Orm::AssignmentPolicy.count).to eq(2)
            expect(Orm::AssignmentQuestionGroup.count).to eq(2)
            expect(Orm::AssignmentQuestionGroupMap.count).to eq(2)
            expect(Orm::Question.count).to eq(1)
          end
        end

        context "copy an assignment to another class without options" do

          let(:acc) { assignment_class.copy :class_id => mapleta_class_2.id }

          it "should copy assignment_class into another class" do
            expect(acc.class_id).to_not be_nil
            expect(acc.class_id).to_not eq(mapleta_class.id)
            expect(acc.class_id).to eq(acc.assignment.class_id)
            expect(Orm::Class.count).to eq(2)
          end

          it "should set start and end date to nil" do
            expect(acc.assignment_policy.start_time).to be_nil
            expect(acc.assignment_policy.end_time).to be_nil
          end

          it "should set the name to be the same as the original" do
            expect(acc.name).to eq(assignment.name)
            expect(acc.name).to eq(acc.assignment.name)
          end
        end

        context "copy an assignment to another class with options" do

          let(:start_time)  { Time.now }
          let(:end_time)    { Time.now + 2.months}
          let(:name)        { "Assignment Copy - Another Class"}
          let(:acc)         { assignment_class.copy(:class_id => mapleta_class_2.id,
                                                  :name => name,
                                                  :start_time => start_time,
                                                  :end_time => end_time) }



          it "should copy assignment to a new class" do
            expect(acc.class_id).to eq(mapleta_class_2.id)
          end

          it "should set the expected dates" do
            expect(acc.assignment_policy.start_time).to eq(start_time)
            expect(acc.assignment_policy.end_time).to eq(end_time)
          end

          it "should copy assignment_class into another class with class, name and dates options" do
            expect(acc.name).to eq(name)
          end

        end

      end
    end
  end
end
