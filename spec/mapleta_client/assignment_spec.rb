require 'spec_helper'

module Maple::MapleTA
  describe Assignment do
    let(:settings)   { RSpec.configuration.maple_settings }
    let(:connection) { Maple::MapleTA::Connection.new RSpec.configuration.maple_settings }
    let(:assignment) {
      Assignment.new(
        :id       => settings['assignment_id'],
        :name     => settings['assignment_name'],
        :class_id => settings['class_id']
      )
    }

    describe "#launch" do
      it "returns a Page::BaseQuestion object" do
        VCR.use_cassette('ws-launcher') do
          assignment.launch(connection, 5).should be_a Page::BaseQuestion
        end
      end
    end
  end
end
