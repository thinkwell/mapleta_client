require 'spec_helper'

module Maple::MapleTA
module Database::Macros
  describe Question do

    before(:all) do
      @connection = spec_maple_connection
      @database_connection = Maple::MapleTA.database_connection
      @connection.connect
      @settings = RSpec.configuration.maple_settings
      @class = @database_connection.class(@settings[:class_id])
    end

    describe "questions" do

      it "should return questions for question_ids" do
        questions = @database_connection.questions(["1","2","3"])
        questions.count.should == 3
      end
    end

    describe "questions_for_class" do

      it "returns all questions with author == classid or with author == parent of class" do
        questions = @database_connection.questions_for_class(@settings[:class_id], nil, 10000)
        questions.should_not be_nil
        authors = questions.map{|q| q['author']}.uniq
        authors.should == [@class['parent'], @class['cid']]
      end

      it "returns count of all questions with author == classid or with author == parent of class" do
        questions_count = @database_connection.questions_for_class_count(@settings[:class_id])
        questions_count.should > 0
      end

      describe "with search" do
        it "should return questions with search in text or name" do
          questions = @database_connection.questions_for_class(@settings[:class_id], "3.8.3", 1000)
          questions.should_not be_nil
        end

        it "should return count of questions with search in text or name" do
          questions_count = @database_connection.questions_for_class_count(@settings[:class_id], "3.8.3")
          questions_count.should > 0
        end
      end
    end


  end
end
end
