module Maple::MapleTA

  # Custom string class used to prevent Mechanize from unescaping HTML in
  # MathML strings
  class RawString

    def initialize(s="")
      @s = s
    end

    def to_s
      @s
    end
  end

end
