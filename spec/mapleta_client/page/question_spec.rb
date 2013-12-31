require 'spec_helper'

module Maple::MapleTA
module Page
  describe Question do

    before(:all) do
      # Fetch from Maple T.A. only once for faster tests
      @settings = RSpec.configuration.maple_settings
      @connection = spec_maple_connection
      @connection.connect
      @database_connection = Maple::MapleTA.database_connection
      @question = @database_connection.questions_for_assignment_class(@settings[:class_id]).first
      url = "contentmanager/DisplayQuestion.do?actionID=display&questionId=#{@question['id']}"
      puts url
      @page = @connection.get_page(url)
    end

    it "parses the question page" do
      @page.should be_a(Maple::MapleTA::Page::Question)
    end
  end
end
end
