module Maple::MapleTA
  module Orm
    class Class < Sequel::Model( Maple::MapleTA.database_connection.dataset[:classes] )

      set_primary_key :cid
      alias id pk

      one_to_many :user_classes, :class => Orm::UserClass, :key => :classid

      plugin :association_dependencies,
        :user_classes => :delete

      # belongs_to :parent_class, :class_name => 'Maple::MapleTA::Orm::Class', :primary_key => 'cid', :foreign_key => 'parent'
      # has_many :children, :class_name => 'Maple::MapleTA::Orm::Class', :primary_key => 'cid', :foreign_key => 'parent'
      # has_many :assignments, :class_name => 'Maple::MapleTA::Orm::Assignment', :foreign_key => 'classid'
      # has_many :class_assignments, :class_name => 'Maple::MapleTA::Orm::AssignmentClass', :foreign_key => 'classid'
    end
  end
end
