require 'spec_helper'

module Maple::MapleTA

  describe WebService do
    before(:each) do
      @connection = spec_maple_connection
      @ws = @connection.ws
    end


    describe "#ping" do
      it "returns true if connection is available" do
        @ws.ping.should == true
      end

      it "returns false for an invalid url" do
        bad_config = RSpec.configuration.maple_settings.dup
        bad_config[:base_url] += 'foo'
        connection = Connection.new(bad_config)
        connection.ws.ping.should == false
      end
    end


    describe "#classes" do
      it "returns an array of Course objects" do
        @connection.connect
        courses = @ws.classes
        courses.should be_a(Array)
        courses.each { |c| c.should be_a(Course) }
      end
    end


    describe "#assignment" do
      it "returns an Assignment object" do
        config = RSpec.configuration.maple_settings
        @connection.connect
        assignment = @ws.assignment(config[:assignment_id])
        assignment.should be_a(Assignment)
      end
    end


    describe "#assignments" do
      it "returns an array of Assignment objects" do
        @connection.connect
        assignments = @ws.assignments
        assignments.should be_a(Array)
        assignments.each { |a| a.should be_a(Assignment) }
      end
    end

  end

end
