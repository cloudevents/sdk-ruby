# frozen_string_literal: true

lib = ::File.expand_path "lib", __dir__
$LOAD_PATH.unshift lib unless $LOAD_PATH.include? lib
require "cloud_events/version"
version = ::CloudEvents::VERSION

::Gem::Specification.new do |spec|
  spec.name = "cloud_events"
  spec.version = version
  spec.licenses = ["Apache-2.0"]
  spec.authors = ["Daniel Azuma"]
  spec.email = ["dazuma@gmail.com"]

  spec.summary = "Ruby SDK for CloudEvents"
  spec.description = \
    "The official Ruby implementation of the CloudEvents Specification." \
    " Provides data types for events, and HTTP/JSON bindings for marshalling" \
    " and unmarshalling event data."
  spec.homepage = "https://github.com/cloudevents/sdk-ruby"

  spec.files = ::Dir.glob("lib/**/*.rb") + ::Dir.glob("*.md") + [".yardopts"]
  spec.require_paths = ["lib"]
  spec.required_ruby_version = ">= 2.5"

  if spec.respond_to? :metadata
    spec.metadata["changelog_uri"] = "https://cloudevents.github.io/sdk-ruby/v#{version}/file.CHANGELOG.html"
    spec.metadata["source_code_uri"] = "https://github.com/cloudevents/sdk-ruby"
    spec.metadata["bug_tracker_uri"] = "https://github.com/cloudevents/sdk-ruby/issues"
    spec.metadata["documentation_uri"] = "https://cloudevents.github.io/sdk-ruby/v#{version}"
  end
end
