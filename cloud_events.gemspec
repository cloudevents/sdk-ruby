# frozen_string_literal: true

lib = ::File.expand_path "lib", __dir__
$LOAD_PATH.unshift lib unless $LOAD_PATH.include? lib
require "cloud_events/version"

::Gem::Specification.new do |spec|
  spec.name = "cloud_events"
  spec.version = ::CloudEvents::VERSION
  spec.licenses = ["Apache-2.0"]
  spec.authors = ["Daniel Azuma"]
  spec.email = ["dazuma@gmail.com"]

  spec.summary = "Ruby SDK for CloudEvents"
  spec.description = "Provides data types to work with CloudEvents specification, and HTTP/JSON bindings."
  spec.homepage = "https://github.com/cloudevents/sdk-ruby"

  spec.files = ::Dir.glob("lib/**/*.rb") + ::Dir.glob("*.md") + [".yardopts"]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.4.0"

  spec.add_development_dependency "google-style", "~> 1.24.0"
  spec.add_development_dependency "minitest", "~> 5.14"
  spec.add_development_dependency "minitest-focus", "~> 1.1"
  spec.add_development_dependency "minitest-rg", "~> 5.2"
  spec.add_development_dependency "redcarpet", "~> 3.5" unless ::RUBY_PLATFORM == "java"
  spec.add_development_dependency "yard", "~> 0.9.24"
end
