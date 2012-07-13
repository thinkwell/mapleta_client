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

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  s.add_runtime_dependency(%q<activesupport>, [">= 0"])
  s.add_runtime_dependency(%q<nokogiri>, ["~> 1.4"])
  # 2.0.1 is causing problems with Net::HTTP::Persistent
  # https://github.com/tenderlove/mechanize/issues/123
  s.add_runtime_dependency(%q<mechanize>, ["= 1.0.0"])
  s.add_runtime_dependency(%q<pg>)
  s.add_runtime_dependency(%q<uuid>, [">= 2.3.0"])

  s.add_development_dependency(%q<rspec>, ["~> 2.6"])
  s.add_development_dependency(%q<bundler>, [">= 0"])
  s.add_development_dependency(%q<rcov>, [">= 0"])
  s.add_development_dependency(%q<rake>, [">= 0"])
end

