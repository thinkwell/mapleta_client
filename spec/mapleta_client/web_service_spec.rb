require 'spec_helper'

module Maple::MapleTA

  describe WebService do
    let(:connection) { Maple::MapleTA::Connection.new RSpec.configuration.maple_settings }
    let(:ws)         { connection.ws }

    describe "#ping" do
      it "returns true if connection is available" do
        VCR.use_cassette('ws-ping') do
          ws.ping.should == true
        end
      end

      it "returns false for an invalid url" do
        bad_config = RSpec.configuration.maple_settings.dup
        bad_config['base_url'] += 'foo'
        connection = Connection.new bad_config
        VCR.use_cassette('ws-ping-bad') do
          connection.ws.ping.should == false
        end
      end
    end


    describe "#classes" do
      it "returns an array of Course objects" do
        VCR.use_cassette('ws-connect') { connection.connect }
        courses = VCR.use_cassette('ws-classes') { ws.classes }
        courses.should be_a(Array)
        courses.each { |c| c.should be_a(Course) }
      end
    end


    describe "#assignment" do
      it "returns an Assignment object" do
        config = RSpec.configuration.maple_settings
        assignment_id = config['assignment_id']
        VCR.use_cassette('ws-connect') { connection.connect }
        assignment = VCR.use_cassette("ws-assignment-#{assignment_id}") { ws.assignment assignment_id }
        assignment.should be_a(Assignment)
      end
    end


    describe "#assignments" do
      it "returns an array of Assignment objects" do
        VCR.use_cassette('ws-connect') { connection.connect }
        assignments = VCR.use_cassette('ws-assignment') { ws.assignments }
        assignments.should be_a(Array)
        assignments.each { |a| a.should be_a(Assignment) }
      end
    end

  end

end
