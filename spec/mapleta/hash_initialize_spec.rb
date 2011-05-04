require 'spec_helper'

module Maple::MapleTA

  class ObjMock
    include HashInitialize
    attr_accessor :shape
    property :foo
    property :color
    property :width, :type => :integer
    property :volume, :type => :float
    property :bounces, :type => :boolean
    property :created, :type => :time_from_s
    property :updated, :type => :time_from_ms
    property :filled_with, :from => :filledWith
    property :num_bounces, :from => :numberOfBounces, :type => :integer
    property :rolls, :default => true

    def foo=(val)
      @foo = 'barbar'
    end

    def foo
      @foo
    end
  end

  describe HashInitialize do

    before(:each) do
      @attrs = {
        :foo => 'bar',
        :width => '42',
        :volume => '45.1',
        :bounces => true,
        :created => '1304529152',
        :updated => '1304529152473',
        :filledWith => 'lead',
        :numberOfBounces => '8',
      }
    end


    context "#initialize" do
      it "works with symbol keys" do
        o = ObjMock.new(:shape => 'circle')
        o.shape.should == 'circle'
      end

      it "works with string keys" do
        o = ObjMock.new('shape' => 'square')
        o.shape.should == 'square'
      end
    end


    context "#hydrate" do
      before(:each) do
        @mock = ObjMock.new
      end

      it "ignores unknown attrs" do
        @mock.hydrate(:test => 'foobar')
      end

      it "uses default values" do
        @mock.rolls.should == true
      end
    end


    context "with properties" do
      before(:each) do
        @mock = ObjMock.new(@attrs)
      end

      it "defines getters" do
        @mock.should respond_to('color')
      end

      it "defines setters" do
        @mock.should respond_to('color=')
      end

      it "does not define translation getters" do
        @mock.should_not respond_to('filledWith')
      end

      it "defines translation setters" do
        @mock.should respond_to('filledWith=')
      end

      it "doesn't override defined accessors" do
        @mock.foo.should == 'barbar'
      end

      it "doesn't set a default value" do
        @mock.color.should == nil
      end

      context "type = :integer" do
        it "performs datatype conversion" do
          @mock.width.should == 42
        end

        it "converts a float to an integer" do
          @mock.width = 54.4
          @mock.width.should == 54
        end

        it "does not convert nil" do
          @mock.width = nil
          @mock.width.should == nil
        end
      end

      context "type = :float" do
        it "performs datatype conversion" do
          @mock.volume.should == 45.1
        end

        it "does not convert nil" do
          @mock.volume = nil
          @mock.volume.should == nil
        end
      end

      context "type = :boolean" do
        it "performs datatype conversion" do
          @mock.bounces.should == true
        end

        it "converts 'false' to false" do
          @mock.bounces = 'false'
          @mock.bounces.should == false
        end

        it "does not convert nil" do
          @mock.bounces = nil
          @mock.bounces.should == nil
        end
      end

      context "type = :time_from_s" do
        it "performs datatype conversion" do
          @mock.created.should be_a(Time)
          @mock.created.should == Time.at(1304529152)
        end

        it "does not convert nil" do
          @mock.created = nil
          @mock.created.should == nil
        end
      end

      context "type = :time_from_ms" do
        it "performs datatype conversion" do
          @mock.updated.should be_a(Time)
          @mock.updated.should == Time.at(1304529152, 473000)
        end

        it "does not convert nil" do
          @mock.updated = nil
          @mock.updated.should == nil
        end

        it "doesn't convert an existing Time object" do
          t = Time.at(130452900, 120462)
          @mock.updated = t
          @mock.updated.should == t
        end
      end

      it "translates using the \"from\" options" do
        @mock.filled_with.should == 'lead'
      end

      it "translates and converts" do
        @mock.num_bounces.should == 8
      end

    end

  end
end
