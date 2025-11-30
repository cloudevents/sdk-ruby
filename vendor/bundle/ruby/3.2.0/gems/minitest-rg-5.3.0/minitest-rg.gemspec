# -*- encoding: utf-8 -*-
# stub: minitest-rg 5.3.0.20231031004948 ruby lib

Gem::Specification.new do |s|
  s.name = "minitest-rg".freeze
  s.version = "5.3.0.20231031004948"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/minitest/minitest-rg/issues", "homepage_uri" => "https://github.com/minitest/minitest-rg" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Mike Moore".freeze]
  s.date = "2023-10-31"
  s.description = "Colored red/green output for Minitest".freeze
  s.email = ["mike@blowmage.com".freeze]
  s.extra_rdoc_files = ["CHANGELOG.rdoc".freeze, "Manifest.txt".freeze, "README.rdoc".freeze]
  s.files = [".autotest".freeze, ".gemtest".freeze, ".rubocop.yml".freeze, "CHANGELOG.rdoc".freeze, "Gemfile".freeze, "LICENSE".freeze, "Manifest.txt".freeze, "README.rdoc".freeze, "Rakefile".freeze, "lib/minitest/rg.rb".freeze, "lib/minitest/rg_plugin.rb".freeze, "minitest-rg.gemspec".freeze, "scripts/run_error".freeze, "scripts/run_fail".freeze, "scripts/run_pass".freeze, "scripts/run_skip".freeze, "test/test_rg.rb".freeze]
  s.homepage = "https://github.com/minitest/minitest-rg".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--main".freeze, "README.rdoc".freeze]
  s.rubygems_version = "3.4.12".freeze
  s.summary = "Red/Green for Minitest".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<minitest>.freeze, ["~> 5.0"])
  s.add_development_dependency(%q<rubocop>.freeze, ["~> 1.57.0"])
  s.add_development_dependency(%q<rdoc>.freeze, [">= 4.0", "< 7"])
  s.add_development_dependency(%q<hoe>.freeze, ["~> 4.0"])
end
