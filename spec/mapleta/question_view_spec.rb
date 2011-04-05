require 'spec_helper'

module Maple::MapleTA
  describe QuestionView do

    before(:all) do
      # Fetch from Maple T.A. only once for faster tests
      @settings = RSpec.configuration.maple_settings
      @values = RSpec.configuration.maple_values
      @connection = spec_maple_connection
      assignment = Assignment.new(
        :id => @settings[:assignment_id],
        :name => @settings[:assignment_name],
        :classId => @settings[:class_id]
      )
      @_qv = assignment.launch(@connection, 5)
    end

    before(:each) do
      # TODO: Can we clone the Nokogiri page?  Right now it persists from test
      # to test
      @qv = @_qv.clone
    end

    it "allows accessing the mechanize page" do
      @qv.page.should be_a(Mechanize::Page)
    end

    it "returns the question number" do
      @qv.number.should == @values[:assignment_question_number]
    end

    it "returns the total number of questions" do
      @qv.total_questions.should == @values[:assignment_question_count]
    end

    it "returns a list of questions" do
      @qv.question_list.should be_a(Array)
      @qv.question_list[0].should == 'Question 1'
    end

    it "returns the point value" do
      @qv.points.should == @values[:assignment_question_points]
    end

    it "returns the question html" do
      html = @qv.html
      html.should be_a(String)
      html.should include(@values[:assignment_question_text])
    end

    it "returns the forms hidden fields" do
      html = @qv.hidden_fields_html
      html.should be_a(String)
      html.should include('input type="hidden"')
    end

    it "returns inline javascript" do
      html = @qv.script_html
      html.should be_a(String)
      html.should =~ /^<script/
    end

    it "allows changing the base uri" do
      @qv.base_url = 'http://thinkwell.com/mapleta/'
      pending
    end

    it "sets the form_param_name to question by default" do
      @qv.hidden_fields_html.should include('question[actionID]')
    end

    it "allows changing the form_param_name" do
      @qv.form_param_name = :foobar
      @qv.hidden_fields_html.should include('foobar[actionID]')
    end

  end
end
