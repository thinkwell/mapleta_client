require 'spec_helper'

module Maple::MapleTA
  describe MathMLString do
    describe "#fix" do

      def normalize(str)
        Nokogiri.XML(str).root.to_s
      end

      it "adds inferred mrow on math element" do
        wrong = "<math xmlns=\"http://www.w3.org/1998/Math/MathML\"><mo>-</mo><mn>4</mn></math>"
        right = "<math><mrow><mo>-</mo><mn>4</mn></mrow></math>"
        mathml = MathMLString.new(wrong)
        mathml.send(:fix).should == normalize(right)
      end

      it "adds inferred mrow on embedded elements" do
        wrong = "<math><mn>2</mn><mo>+</mo><msqrt><mn>25</mn><mo>+</mo><mn>5</mn></msqrt></math>"
        right = "<math><mrow><mn>2</mn><mo>+</mo><msqrt><mrow><mn>25</mn><mo>+</mo><mn>5</mn></mrow></msqrt></mrow></math>"
        mathml = MathMLString.new(wrong)
        mathml.send(:fix).should == normalize(right)
      end

      it "doesn't modify correct elements" do
        right = "<math><mrow><mo>-</mo><mn>4</mn></mrow></math>"
        mathml = MathMLString.new(right)
        mathml.send(:fix).should == normalize(right)
      end

      it "does not convert entities" do
        right = "<math><mrow><mo>&minus;</mo><mn>4</mn></mrow></math>"
        normalize(right).should =~ /<mo>&minus;<\/mo>/
        mathml = MathMLString.new(right)
        mathml.send(:fix).should == normalize(right)
      end
    end
  end
end
