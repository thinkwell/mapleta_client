module Maple::MapleTA
  class Course
    include HashInitialize
    property :id, :type => :integer
    property :name
    property :instructor
  end
end
