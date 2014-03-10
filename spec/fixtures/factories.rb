require 'ostruct'

FactoryGirl.define do
  factory :author, class: Maple::MapleTA::Orm::Author do
    to_create { |instance| instance.save }

    sequence(:id)  { |num| num }
    sequence(:uid) { |num| num }
    instance true
    display_name 'me'
    default_school 'UT'
    created Time.now
  end

  factory :class, class: Maple::MapleTA::Orm::Class do
    to_create { |instance| puts instance.save.inspect }

    name 'Algebra'
    dirname 'dirname'
  end

  factory :question, class: Maple::MapleTA::Orm::Question do
    to_create { |instance| instance.save }

    name 'Question'
    mode '...'
    questiontext '...'
    questionfields '...'
    algorithm '...'
    description '...'
    hint '...'
    comment '...'
    info '...'
    solution '...'
    annotation '...'
    modedescription '...'
    tags '...'

    modified_by 'Me'
    revision '1'
    attribute_author false
    deleted false

    created Time.now
    lastmodified Time.now
  end

  factory :assignment, class: Maple::MapleTA::Orm::Assignment do
    to_create { |instance| instance.save }

    name 'Assignment'
    weighting 1

    # primary_key :id
    # foreign_key :classid, :classes, :null => false, :key => [:cid]
    # Float :totalpoints
    # DateTime :lastmodified, :null => false
    # String :uid, :size => 50
    # TrueClass :adaptive, :default => false, :null => false
  end

  factory :user_class, class: Maple::MapleTA::Orm::UserClass do
    to_create { |instance| instance.save }
  end
end
