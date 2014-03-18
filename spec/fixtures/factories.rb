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

    sequence(:name) { |num| "Algebra #{num}" }
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
    reworkable false
    printable true
    weighting 0
    insession_grade false
    show_current_grade  false
  end

  factory :user_class, class: Maple::MapleTA::Orm::UserClass do
    to_create { |instance| instance.save }
  end
end
