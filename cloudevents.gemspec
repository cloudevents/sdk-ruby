
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "cloudevents/version"

Gem::Specification.new do |spec|
  spec.name = "cloudevents"
  spec.version = Cloudevents::VERSION
  spec.licenses = ["Apache-2.0"]
  spec.authors = ["Tim Fauseweh", "Fabian Mersch"]
  spec.email = ["fauseweh@gmail.com", "fabianmersch@gmail.com"]

  spec.summary = %q{Ruby SDK for CloudEvents}
  spec.description = %q{Provides primitives to work with CloudEvents specification.}
  spec.homepage = "https://github.com/cloudevents/sdk-ruby"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path("..", __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features|examples)/}) }
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.2.0"
end
