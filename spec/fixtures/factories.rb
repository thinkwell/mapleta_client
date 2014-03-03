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

  factory :class, class: Maple::MapleTA::Orm::TAClass do
    to_create { |instance| instance.save }

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
end
