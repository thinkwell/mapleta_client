# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "mapleta_client/version"

Gem::Specification.new do |s|
  s.name        = "mapleta_client"
  s.version     = Maple::MapleTA::VERSION
  s.authors     = ["Brandon Turner"]
  s.email       = ["bt@brandonturner.net"]
  s.homepage    = "http://github.com/thinkwell/mapleta_client"
  s.summary     = %q{API bindings for MapleTA}
  s.description = %q{Provides API bindings for Maple T.A.}
  s.licenses    = ["MIT"]

  s.rubyforge_project = "mapleta_client"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency     "activesupport"
  s.add_runtime_dependency     "nokogiri", "1.5.0"
  # 2.0.1 is causing problems with Net::HTTP::Persistent
  # https://github.com/tenderlove/mechanize/issues/123
  s.add_runtime_dependency     "mechanize", "1.0.0"
  s.add_runtime_dependency     "pg", ">= 0.14.0"
  s.add_runtime_dependency     "uuid", ">= 2.3.0"
  s.add_runtime_dependency     "sequel", "~> 4.9"
  s.add_runtime_dependency     "sequel_deep_dup", "~> 0.2.1"

  s.add_development_dependency "activesupport", "~> 2.3.14"
  s.add_development_dependency "bundler"
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec", "~> 2.14"
  s.add_development_dependency "webmock", "~> 1.16"
  s.add_development_dependency "vcr", "~> 2.8"
  s.add_development_dependency "builder", "~> 3.2"
  s.add_development_dependency "factory_girl"
  s.add_development_dependency "tzinfo"
  s.add_development_dependency "iconv"
  # s.add_development_dependency "rcov", ">= 0"
end
