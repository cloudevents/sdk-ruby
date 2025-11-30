# -*- encoding: utf-8 -*-
# stub: memoist3 1.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "memoist3".freeze
  s.version = "1.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Joshua Peek".freeze, "Tarmo T\u00E4nav".freeze, "Jeremy Kemper".freeze, "Eugene Pimenov".freeze, "Xavier Noria".freeze, "Niels Ganser".freeze, "Carl Lerche & Yehuda Katz".freeze, "jeem".freeze, "Jay Pignata".freeze, "Damien Mathieu".freeze, "Jos\u00E9 Valim".freeze, "Matthew Rudy Jacobs".freeze, "Jan Sterba".freeze]
  s.date = "2022-01-09"
  s.email = ["josh@joshpeek.com".freeze, "tarmo@itech.ee".freeze, "jeremy@bitsweat.net".freeze, "libc@mac.com".freeze, "fxn@hashref.com".freeze, "niels@herimedia.co".freeze, "wycats@gmail.com".freeze, "jeem@hughesorama.com".freeze, "john.pignata@gmail.com".freeze, "42@dmathieu.com".freeze, "jose.valim@gmail.com".freeze, "matthewrudyjacobs@gmail.com".freeze, "info@jansterba.com".freeze]
  s.homepage = "https://github.com/honzasterba/memoist".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7.2".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "memoize methods invocation".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<benchmark-ips>.freeze, [">= 0"])
  s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.10"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
end
