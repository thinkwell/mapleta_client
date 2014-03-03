require 'spec_helper'

module Maple::MapleTA
  module Page
    describe Question do
      let(:connection) { Maple::MapleTA::Connection.new RSpec.configuration.maple_settings }
      let(:database)   { RSpec.configuration.database_connection }
      let(:settings)   { RSpec.configuration.maple_settings }

      before do
        VCR.use_cassette('ws-connect') do
          connection.connect
        end
      end

      it "parses the question page" do
        url  = "contentmanager/DisplayQuestion.do?actionID=display&questionId=6551"
        page = VCR.use_cassette('ws-question-6551') { connection.get_page url }
        page.should be_a Maple::MapleTA::Page::Question
      end
    end
  end
end
