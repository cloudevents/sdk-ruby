# -*- encoding: utf-8 -*-
# stub: cucumber 9.2.1 ruby lib

Gem::Specification.new do |s|
  s.name = "cucumber".freeze
  s.version = "9.2.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 3.0.1".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/cucumber/cucumber-ruby/issues", "changelog_uri" => "https://github.com/cucumber/cucumber-ruby/blob/main/CHANGELOG.md", "documentation_uri" => "https://www.rubydoc.info/github/cucumber/cucumber-ruby/", "mailing_list_uri" => "https://groups.google.com/forum/#!forum/cukes", "source_code_uri" => "https://github.com/cucumber/cucumber-ruby" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Aslak Helles\u00F8y".freeze, "Matt Wynne".freeze, "Steve Tooke".freeze]
  s.date = "2025-01-12"
  s.description = "Behaviour Driven Development with elegance and joy".freeze
  s.email = "cukes@googlegroups.com".freeze
  s.executables = ["cucumber".freeze]
  s.files = ["bin/cucumber".freeze]
  s.homepage = "https://cucumber.io/".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--charset=UTF-8".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "cucumber-9.2.1".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<builder>.freeze, ["~> 3.2"])
  s.add_runtime_dependency(%q<cucumber-ci-environment>.freeze, ["> 9", "< 11"])
  s.add_runtime_dependency(%q<cucumber-core>.freeze, ["> 13", "< 14"])
  s.add_runtime_dependency(%q<cucumber-cucumber-expressions>.freeze, ["~> 17.0"])
  s.add_runtime_dependency(%q<cucumber-gherkin>.freeze, ["> 24", "< 28"])
  s.add_runtime_dependency(%q<cucumber-html-formatter>.freeze, ["> 20.3", "< 22"])
  s.add_runtime_dependency(%q<cucumber-messages>.freeze, ["> 19", "< 25"])
  s.add_runtime_dependency(%q<diff-lcs>.freeze, ["~> 1.5"])
  s.add_runtime_dependency(%q<mini_mime>.freeze, ["~> 1.1"])
  s.add_runtime_dependency(%q<multi_test>.freeze, ["~> 1.1"])
  s.add_runtime_dependency(%q<sys-uname>.freeze, ["~> 1.2"])
  s.add_development_dependency(%q<cucumber-compatibility-kit>.freeze, ["~> 15.0"])
  s.add_development_dependency(%q<nokogiri>.freeze, ["~> 1.14"])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.1"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.12"])
  s.add_development_dependency(%q<rubocop>.freeze, ["~> 1.56.4"])
  s.add_development_dependency(%q<rubocop-capybara>.freeze, ["~> 2.19.0"])
  s.add_development_dependency(%q<rubocop-packaging>.freeze, ["~> 0.5.2"])
  s.add_development_dependency(%q<rubocop-rake>.freeze, ["~> 0.6.0"])
  s.add_development_dependency(%q<rubocop-rspec>.freeze, ["~> 2.25.0"])
  s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.22.0"])
  s.add_development_dependency(%q<webrick>.freeze, ["~> 1.8"])
end
