require 'nokogiri'

module Maple::MapleTA
  class MathMLString

    INFERRED_MROW_ELEMENTS = %w(msqrt mstyle merror mpadded mphantom menclose mtd math)

    def initialize(mathml="")
      @orig_mathml = mathml
    end

    def to_s
      @fixed_mathml ||= fix
    end

    private

    def fix
      @doc = ::Nokogiri.XML(@orig_mathml)
      @doc.remove_namespaces!
      fix_inferred_mrow
      if defined? Rails
        Rails.logger.warn "orig=#{@orig_mathml}"
        Rails.logger.warn "fixed=#{@doc.root.to_s}"
      end
      @doc.root.to_s
    end

    def fix_inferred_mrow
      @doc.xpath(INFERRED_MROW_ELEMENTS.map {|e| "//#{e}"}.join(' | ')).each do |node|
        unless node.children.length == 1
          mrow = @doc.create_element 'mrow'
          node.children.each {|n| n.parent = mrow}
          node.add_child mrow
        end
      end
    end
  end
end
