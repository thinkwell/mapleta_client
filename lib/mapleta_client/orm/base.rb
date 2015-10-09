module Maple::MapleTA::Orm
  class Base < ActiveRecord::Base
    self.abstract_class = true

    def self.namespace(name)
      "Maple::MapleTA::Orm::#{name}"
    end

  end
end