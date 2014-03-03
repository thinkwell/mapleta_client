require 'spec_helper'

module Maple::MapleTA
  class MockSpecConnection < Maple::MapleTA::Connection
    include Communication
  end

  describe Communication::InstanceMethods do
    let(:connection) { MockSpecConnection.new }
    let(:base_url)   { RSpec.configuration.maple_settings['base_url'] }

    before(:each) do
      connection.base_url = base_url
    end

    it "adds instance methods to a class when included" do
      connection.should respond_to(:fetch_response)
      connection.should respond_to(:fetch_page)
      connection.should respond_to(:fetch_api)
      connection.should respond_to(:fetch_api_page)
    end

    describe "#fetch_response" do
      it "fetches a response over HTTP" do
        VCR.use_cassette('get-mapleta') do
          connection.fetch_response(base_url).should be_a Net::HTTPResponse
        end
      end

      it "accepts a block" do
        VCR.use_cassette('get-mapleta') do
          expect { |block| connection.fetch_response base_url, &block }.
            to yield_with_args an_instance_of Net::HTTP::Get
        end
      end

      it "sets the JSESSION cookie if session exists" do
        connection.stub(:session).and_return('foobar')

        block = lambda do |request|
          request['Cookie'].should == 'JSESSIONID=foobar'
        end

        VCR.use_cassette('get-mapleta') do
          connection.fetch_response(base_url, &block)
        end
      end

      it "raises a NetworkError when errors occur" do
        Net::HTTP.stub(:new).and_raise(Timeout::Error)
        expect {
          connection.fetch_response(base_url)
        }.to raise_error(Errors::NetworkError)
      end
    end

    it "fetches a Mechanize page" do
      VCR.use_cassette('get-page-mapleta') do
        connection.fetch_page(base_url).should be_a Mechanize::Page
      end
    end

    describe "#fetch_api" do
      it "uses the correct URL" do
        expected_uri = URI.parse("#{base_url}/ws/ping")

        connection.should_receive(:fetch_response).with(expected_uri, :post).and_throw(Exception)
        expect {
          connection.fetch_api('ping')
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
