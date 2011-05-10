# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{mapleta}
  s.version = "0.0.10"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Brandon Turner"]
  s.date = %q{2011-05-10}
  s.description = %q{Provides API bindings for MapleTA}
  s.email = %q{brandont@thinkwell.com}
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc"
  ]
  s.files = [
    ".document",
    ".rspec",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE.txt",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "lib/mapleta.rb",
    "lib/mapleta/assignment.rb",
    "lib/mapleta/communication.rb",
    "lib/mapleta/connection.rb",
    "lib/mapleta/course.rb",
    "lib/mapleta/errors/invalid_response_error.rb",
    "lib/mapleta/errors/mapleta_error.rb",
    "lib/mapleta/errors/network_error.rb",
    "lib/mapleta/errors/not_connected_error.rb",
    "lib/mapleta/errors/session_expired_error.rb",
    "lib/mapleta/errors/unexpected_content_error.rb",
    "lib/mapleta/hash_initialize.rb",
    "lib/mapleta/page.rb",
    "lib/mapleta/page/assignment_question.rb",
    "lib/mapleta/page/base.rb",
    "lib/mapleta/page/base_question.rb",
    "lib/mapleta/page/error.rb",
    "lib/mapleta/page/feedback.rb",
    "lib/mapleta/page/form.rb",
    "lib/mapleta/page/grade.rb",
    "lib/mapleta/page/other_active_assignment.rb",
    "lib/mapleta/page/preview.rb",
    "lib/mapleta/page/restricted_assignment.rb",
    "lib/mapleta/page/solution.rb",
    "lib/mapleta/page/study_feedback.rb",
    "lib/mapleta/page/study_question.rb",
    "lib/mapleta/page/time_limit_exceeded.rb",
    "lib/mapleta/raw_string.rb",
    "lib/mapleta/web_service.rb",
    "mapleta.gemspec",
    "spec/mapleta/assignment_spec.rb",
    "spec/mapleta/communication_spec.rb",
    "spec/mapleta/connection_spec.rb",
    "spec/mapleta/hash_initialize_spec.rb",
    "spec/mapleta/question_view_spec.rb",
    "spec/mapleta/web_service_spec.rb",
    "spec/spec_helper.rb"
  ]
  s.homepage = %q{http://github.com/thinkwell/mapleta}
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.6.0}
  s.summary = %q{API bindings for MapleTA}
  s.test_files = [
    "spec/mapleta/assignment_spec.rb",
    "spec/mapleta/communication_spec.rb",
    "spec/mapleta/connection_spec.rb",
    "spec/mapleta/hash_initialize_spec.rb",
    "spec/mapleta/question_view_spec.rb",
    "spec/mapleta/web_service_spec.rb",
    "spec/spec_helper.rb"
  ]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activesupport>, [">= 0"])
      s.add_runtime_dependency(%q<nokogiri>, [">= 0"])
      s.add_runtime_dependency(%q<mechanize>, [">= 0"])
      s.add_development_dependency(%q<rspec>, ["~> 2.5"])
      s.add_development_dependency(%q<bundler>, [">= 0"])
      s.add_development_dependency(%q<jeweler>, [">= 0"])
      s.add_development_dependency(%q<rcov>, [">= 0"])
    else
      s.add_dependency(%q<activesupport>, [">= 0"])
      s.add_dependency(%q<nokogiri>, [">= 0"])
      s.add_dependency(%q<mechanize>, [">= 0"])
      s.add_dependency(%q<rspec>, ["~> 2.5"])
      s.add_dependency(%q<bundler>, [">= 0"])
      s.add_dependency(%q<jeweler>, [">= 0"])
      s.add_dependency(%q<rcov>, [">= 0"])
    end
  else
    s.add_dependency(%q<activesupport>, [">= 0"])
    s.add_dependency(%q<nokogiri>, [">= 0"])
    s.add_dependency(%q<mechanize>, [">= 0"])
    s.add_dependency(%q<rspec>, ["~> 2.5"])
    s.add_dependency(%q<bundler>, [">= 0"])
    s.add_dependency(%q<jeweler>, [">= 0"])
    s.add_dependency(%q<rcov>, [">= 0"])
  end
end

