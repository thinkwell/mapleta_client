require 'spec_helper'


module Maple::MapleTA
  class MockSpecConnection < Maple::MapleTA::Connection
    include Communication
  end

  describe Communication::InstanceMethods do
    before(:each) do
      @settings = RSpec.configuration.maple_settings
      @connection = MockSpecConnection.new
      @connection.base_url = @settings[:base_url]
    end

    it "adds instance methods to a class when included" do
      @connection.should respond_to(:fetch_response)
      @connection.should respond_to(:fetch_page)
      @connection.should respond_to(:fetch_api)
      @connection.should respond_to(:fetch_api_page)
    end

    describe "#fetch_response" do
      it "fetches a response over HTTP" do
        @connection.fetch_response(@settings[:base_url]).should be_a(Net::HTTPResponse)
      end

      it "accepts a block" do
        block_called = 0
        @connection.fetch_response(@settings[:base_url]) do |request|
          block_called += 1
          request.should be_a(Net::HTTPRequest)
        end
        block_called.should == 1
      end

      it "sets the JSESSION cookie if session exists" do
        block_called = 0
        @connection.stub(:session).and_return('foobar')
        @connection.fetch_response(@settings[:base_url]) do |request|
          block_called += 1
          request['Cookie'].should == 'JSESSIONID=foobar'
        end
        block_called.should == 1
      end

      it "raises a NetworkError when errors occur" do
        Net::HTTP.stub(:new).and_raise(Timeout::Error)
        expect {
          @connection.fetch_response(@settings[:base_url])
        }.to raise_error(Errors::NetworkError)
      end
    end

    it "fetches a Mechanize page" do
      @connection.fetch_page(@settings[:base_url]).should be_a(Mechanize::Page)
    end

    describe "#fetch_api" do

      it "uses the correct URL" do
        expected_uri = URI.parse("#{@settings[:base_url]}/ws/ping")
        @connection.should_receive(:fetch_response).with(expected_uri, :post).and_throw(Exception)
        expect {
          @connection.fetch_api('ping')
        }.to raise_error
      end
    end

  end



  describe Communication::ClassMethods do

    describe "#abs_url_for" do
      it "returns absolute urls unmodified" do
        ['http://www.thinkwell.com/', 'https://www.thinkwell.com/', 'ftp://ftp.thinkwell.com', 'market://cool'].each do |url|
          MockSpecConnection.abs_url_for(url, 'http://www.foobar.com/').should == url
        end
      end

      it "returns an absolute url for a root-relative url" do
        MockSpecConnection.abs_url_for('/images/123.gif', 'http://www.foobar.com/foo').should == "http://www.foobar.com/images/123.gif"
      end

      it "returns an absolute url for a relative url" do
        MockSpecConnection.abs_url_for('http.gif', 'http://www.foobar.com/foo').should == "http://www.foobar.com/foo/http.gif"
      end
    end

  end
end
