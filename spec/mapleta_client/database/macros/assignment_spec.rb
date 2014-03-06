require 'spec_helper'

module Maple::MapleTA
  module Database::Macros
    describe Assignment do
      let(:settings)      { RSpec.configuration.maple_settings }
      let(:database)      { RSpec.configuration.database_connection }
      let(:questions)     {
        id = database.dataset[:question].insert(
          name: 'Example question',
          mode: '?',
          questiontext: '?',
          questionfields: '?',
          created: 'now()',
          algorithm: '?',
          description: '?',
          hint: '?',
          comment: '?',
          info: '?',
          solution: '?',
          lastmodified: 'now()',
          annotation: '?',
          modedescription: '?',
          tags: '?',
          author: mapleta_class.id
        )

        [ {'name' => 'Example question', 'id' => id} ]
      }

      let(:other_questions)     {
        id = database.dataset[:question].insert(
          name: 'Example question 2',
          mode: '?',
          questiontext: '?',
          questionfields: '?',
          created: 'now()',
          algorithm: '?',
          description: '?',
          hint: '?',
          comment: '?',
          info: '?',
          solution: '?',
          lastmodified: 'now()',
          annotation: '?',
          modedescription: '?',
          tags: '?',
          author: mapleta_class.id
        )

        [ {'name' => 'Example question 2', 'id' => id} ]
      }

      let(:mapleta_class) {
        cid = database.dataset[:classes].insert(name: 'Example class', dirname: 'dirname?')
        double 'Class', id: cid
      }

      let(:assignment) {
        Maple::MapleTA::Assignment.new(
          :name       => "test assignment",
          :class_id   => mapleta_class.id,
          :questions  => questions,
          :reworkable => false,
          :printable  => true
        )
      }

      before(:each) do
        @assignment_id = database.create_assignment assignment
      end

      describe "Assignment creation" do
        it "should create a new assignment" do
          @assignment_id.should_not be_nil

          assignment = database.assignment mapleta_class.id
          assignment.should_not be_nil
          assignment['name'].should == "test assignment"
        end

        it "should create the assignment question group for each question" do
          assignment_question_groups = database.assignment_question_groups @assignment_id
          assignment_question_groups.count.should == 1
          assignment_question_groups.first['name'].should == 'Example question'
        end
        
        it "creates the assignment question group map" do
          pending
        end

        it "should create the assignment class" do
          assignment_class = database.assignment_class mapleta_class.id
          assignment_class.should_not be_nil
          assignment_class['assignmentid'].should == @assignment_id
          assignment_class['name'].should == "test assignment"
        end

        it "should create the assignment policy" do
          assignment_class  = database.assignment_class mapleta_class.id
          assignment_policy = database.assignment_policy assignment_class['id']
          assignment_policy.should_not be_nil
          assignment_policy['reworkable'].should be false
          assignment_policy['printable'].should be true
        end
      end

      describe "update_assignment" do
        before(:each) do
          assignment.name       = "test assignment edited"
          assignment.questions  = other_questions
          assignment.reworkable = true
          assignment.printable  = false
          assignment.id         = @assignment_id
          database.edit_assignment assignment
        end

        it "should update the assignment" do
          assignment = database.assignment mapleta_class.id
          assignment.should_not be_nil
          assignment['name'].should == "test assignment edited"
        end

        it "should update the assignment_question_groups" do
          assignment_question_groups = database.assignment_question_groups @assignment_id
          assignment_question_groups.count.should == 1
          assignment_question_groups.first['name'].should == 'Example question 2'
        end

        it "should update the assignment_class" do
          assignment_class = database.assignment_class(mapleta_class.id)
          assignment_class.should_not be_nil
          assignment_class['assignmentid'].should == @assignment_id
          assignment_class['name'].should == "test assignment edited"
        end

        it "should update the assignment_policy" do
          assignment_class = database.assignment_class mapleta_class.id
          assignment_policy = database.assignment_policy assignment_class['id']
          assignment_policy.should_not be_nil
          assignment_policy['reworkable'].should be true
          assignment_policy['printable'].should be false
        end
      end

      describe "copy_assignment_to_class" do
        it "should create a new assignment_class" do
          assignment_class = database.exec("SELECT * FROM assignment_class limit 1").first
          new_assignment_class_id = database.copy_assignment_to_class assignment_class['id'], mapleta_class.id
          new_assignment_class_id.should_not be_nil
        end
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
