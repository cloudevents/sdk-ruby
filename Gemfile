# frozen_string_literal: true

source "https://rubygems.org"
gemspec

gem "cucumber", "~> 9.2"
gem "minitest", ">= 5.26", "< 7"
gem "minitest-focus", "~> 1.4"
gem "minitest-rg", "~> 5.3"
gem "rack", "~> 3.2"
gem "redcarpet", "~> 3.6" unless ::RUBY_PLATFORM == "java"
gem "rubocop", "~> 1.82"
gem "toys-core", "~> 0.19"
gem "webrick", "~> 1.9"
# win32ole is required transitively by cucumber via sys-uname, and not declared
# as a dependency as of sys-uname 1.4.1. But it is no longer a default gem as
# of Ruby 4.0, and so must be included explicitly in the Gemfile for now. This
# can be removed once sys-uname gets fixed.
gem "win32ole", "~> 1.9" if ::RbConfig::CONFIG["host_os"] =~ /mswin|msys|mingw|cygwin|bccwin|wince|emc/
gem "yard", "~> 0.9.38"
