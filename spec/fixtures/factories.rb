require 'ostruct'

ns = Maple::MapleTA::Orm

FactoryGirl.define do
  factory :class, :class => ns::Class do
    to_create { |instance| puts instance.save.inspect }

    sequence(:name) { |num| "Algebra #{num}" }
    dirname 'dirname'
  end

  factory :assignment, :class => ns::Assignment do
    to_create { |instance| instance.save }

    name 'Assignment'
    reworkable false
    printable true
    weighting 0
    insession_grade false
    show_current_grade  false
  end

  factory :assignment_class, :class => ns::AssignmentClass do
    to_create { |instance| instance.save }
    sequence(:name) { |num| "Assignment class #{num}" }
    totalpoints 1
    weighting   1
  end

  factory :assignment_policy, :class => ns::AssignmentPolicy do
    to_create { |instance| instance.save }

    show_current_grade true
    insession_grade true
    reworkable true
    printable true
    mode 0
    show_final_grade_feedback true
  end

  factory :author do
    to_create { |instance| instance.save }

    sequence(:id)  { |num| num }
    sequence(:uid) { |num| num }
    instance true
    display_name 'me'
    default_school 'UT'
    created Time.now
  end

  factory :question, :class => ns::Question do
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

  factory :user_class, :class => ns::UserClass do
    to_create { |instance| instance.save }
  end

  factory :assignment_question_group, :class => ns::AssignmentQuestionGroup do
    to_create { |instance| instance.save }
  end

  factory :assignment_question_group_map, :class => ns::AssignmentQuestionGroupMap do
    to_create { |instance| instance.save }
  end
end
