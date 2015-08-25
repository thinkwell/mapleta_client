module Maple::MapleTA::Orm
  class Base < ActiveRecord::Base
    self.abstract_class = true
  end
end