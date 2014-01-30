module Maple::MapleTA
  module Orm
    class Class < ActiveRecord::Base
      include Maple::MapleTA::Orm

      set_primary_key 'cid'

      belongs_to :parent_class, :class_name => 'Maple::MapleTA::Orm::Class', :primary_key => 'cid', :foreign_key => 'parent'
      has_many :children, :class_name => 'Maple::MapleTA::Orm::Class', :primary_key => 'cid', :foreign_key => 'parent'
      has_many :assignments, :class_name => 'Maple::MapleTA::Orm::Assignment', :foreign_key => 'classid'
      has_many :class_assignments, :class_name => 'Maple::MapleTA::Orm::AssignmentClass', :foreign_key => 'classid'

    end
  end
end