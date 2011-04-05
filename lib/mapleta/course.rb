module Maple::MapleTA
  class Course
    include HashInitialize
    attr_accessor :id, :name, :instructor
  end
end
