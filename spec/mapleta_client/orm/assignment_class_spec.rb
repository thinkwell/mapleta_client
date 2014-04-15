require 'spec_helper'

module Maple::MapleTA
  module Orm
    describe AssignmentClass do
      let(:mapleta_class)     { create :class }
      let(:assignment)        { create(:assignment, :name => "test assignment", :class_id => mapleta_class.id) }
      let(:assignment_class)  { build(:assignment_class, :class_id => mapleta_class.id, :name => assignment.name) }
      let(:assignment_policy) { build(:assignment_policy)}

      describe 'creating an assignment class' do

        before(:each) do
          assignment.save
          assignment_class.assignmentid = assignment.id
          assignment_class.save
          assignment_policy.assignment_class_id = assignment_class.id
          assignment_policy.save
        end

        describe "creating an assignment and related records" do
          it "should create a new assignment, assignment class and assignment policy" do
            assignment.reload
            assignment_class.reload
            assignment.should_not be_nil
            assignment_class.should_not be_nil
            assignment_class.name.should == "test assignment"
            assignment_policy.reload
            assignment_policy.should_not be_nil
          end

          it "should copy assignment class and associated records" do
            assignment_class_copy = assignment_class.copy
            assignment_class_copy.should_not be_nil
            assignment_class_copy.assignment.id.should_not eq(assignment.id)
          end
        end
      end

    end
  end
end
