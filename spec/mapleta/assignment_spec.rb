require 'spec_helper'

module Maple::MapleTA
  describe Assignment do

    before(:each) do
      @settings = RSpec.configuration.maple_settings
      @connection = spec_maple_connection
      @assignment = Assignment.new(
        :id => @settings[:assignment_id],
        :name => @settings[:assignment_name],
        :classId => @settings[:class_id]
      )
    end

    describe "#launch" do
      it "returns a Page::BaseQuestion object" do
        @assignment.launch(@connection, 5).should be_a(Page::BaseQuestion)
      end
    end
  end
end
