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

    describe "questions_for_class" do

      it "returns all questions with author == classid or with author == parent of class" do
        questions = @database_connection.questions_for_class(@settings[:class_id])
        questions.should_not be_nil
        authors = questions.map{|q| q['author']}.uniq
        authors.should == [@class['cid'], @class['parent']]
      end

    end


  end
end
end
