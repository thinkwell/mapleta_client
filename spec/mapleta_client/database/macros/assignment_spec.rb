require 'spec_helper'

module Maple::MapleTA
  module Database::Macros
    describe Assignment do
      let(:settings)      { RSpec.configuration.maple_settings }
      let(:database)      { RSpec.configuration.database_connection }
      let(:questions)     { 
        result = database.exec <<-SQL
         INSERT INTO question (name, mode, questiontext, questionfields,
            created, algorithm, description, hint, comment, info,
            solution, lastmodified, annotation, modedescription,
            tags, author) 
         VALUES ('Example question', '?', '?',
            '?', now(), '?', '?', '?', '?', '?',
            '?', now(), '?', '?',
            '?', #{mapleta_class.id})
         RETURNING id
        SQL

        [ {'id' => result.values.join.to_i, 'name' => 'Example question'} ]
      }
      let(:other_questions)     { 
        result = database.exec <<-SQL
         INSERT INTO question (name, mode, questiontext, questionfields,
            created, algorithm, description, hint, comment, info,
            solution, lastmodified, annotation, modedescription,
            tags, author) 
         VALUES ('Example question 2', '?', '?',
            '?', now(), '?', '?', '?', '?', '?',
            '?', now(), '?', '?',
            '?', #{mapleta_class.id})
         RETURNING id
        SQL

        [ {'id' => result.values.join.to_i, 'name' => 'Example question 2'} ]
      }
      let(:mapleta_class) {
        result = database.exec <<-SQL
         INSERT INTO classes (name, dirname) VALUES ('Example class', 'dirname?')
         RETURNING cid
        SQL

        double 'Class', id: result.values.join.to_i
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
        @new_assignment_id = database.create_assignment assignment
      end

      describe "Assignment creation" do
        it "should create a new assignment" do
          @new_assignment_id.should_not be_nil

          assignment = database.assignment mapleta_class.id
          assignment.should_not be_nil
          assignment['name'].should == "test assignment"
        end

        it "should create the assignment_question_group for each question" do
          assignment_question_groups = database.assignment_question_groups @new_assignment_id
          assignment_question_groups.count.should == 1
          assignment_question_groups.first['name'].should == 'Example question'
        end

        it "should create the assignment_class" do
          assignment_class = database.assignment_class mapleta_class.id
          assignment_class.should_not be_nil
          assignment_class['assignmentid'].should == @new_assignment_id.to_s
          assignment_class['name'].should == "test assignment"
        end

        it "should create the assignment_policy" do
          assignment_class  = database.assignment_class mapleta_class.id
          assignment_policy = database.assignment_policy(assignment_class['id'])
          assignment_policy.should_not be_nil
          assignment_policy['reworkable'].should == 'f'
          assignment_policy['printable'].should == 't'
        end
      end

      describe "update_assignment" do
        before(:each) do
          assignment.name       = "test assignment edited"
          assignment.questions  = other_questions
          assignment.reworkable = true
          assignment.printable  = false
          assignment.id         = @new_assignment_id
          database.edit_assignment assignment
        end

        it "should update the assignment" do
          assignment = database.assignment mapleta_class.id
          assignment.should_not be_nil
          assignment['name'].should == "test assignment edited"
        end

        it "should update the assignment_question_groups" do
          assignment_question_groups = database.assignment_question_groups @new_assignment_id
          assignment_question_groups.count.should == 1
          assignment_question_groups.first['name'].should == 'Example question 2'
        end

        it "should update the assignment_class" do
          assignment_class = database.assignment_class(mapleta_class.id)
          assignment_class.should_not be_nil
          assignment_class['assignmentid'].should == @new_assignment_id.to_s
          assignment_class['name'].should == "test assignment edited"
        end

        it "should update the assignment_policy" do
          assignment_class = database.assignment_class mapleta_class.id
          assignment_policy = database.assignment_policy assignment_class['id']
          assignment_policy.should_not be_nil
          assignment_policy['reworkable'].should == 't'
          assignment_policy['printable'].should == 'f'
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
