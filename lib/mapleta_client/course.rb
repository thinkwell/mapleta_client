module Maple::MapleTA
  class Course
    attr_accessor :id, :name, :instructor

    def initialize(attrs = {})
      self.attributes = attrs
    end

    def attributes= attrs
      attrs.each { |key, val| send("#{key.to_s}=", val) }
    end
  end
end
