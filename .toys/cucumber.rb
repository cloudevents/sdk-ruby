# frozen_string_literal: true

toys_version! ">= 0.16"

desc "Run cucumber tests"

remaining_args :features

include :bundler
include :exec, e: true
include :git_cache
include :fileutils

def run
  setup_features
  cmd = ["cucumber", "--publish-quiet"]
  cmd += (verbosity > 0 ? ["--format=pretty"] : ["--format=progress"])
  cmd += features
  exec cmd
end

def setup_features
  remote_features = git_cache.find("https://github.com/cloudevents/conformance", path: "features")
  local_features = File.join(context_directory, "features", "conformance")
  rm_rf(local_features)
  cp_r(remote_features, local_features)
end
