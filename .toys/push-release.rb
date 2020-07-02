# frozen_string_literal: true

desc "Build and push a release of cloud_events"

long_desc \
  "This tool performs an official release of cloud_events. It is intended to" \
  " be called from within a Github Actions workflow, and may not work if run" \
  " locally, unless the environment is set up as expected."

flag :release_ref, accept: String, default: ::ENV["GITHUB_REF"]
flag :api_key, accept: String, default: ::ENV["RUBYGEMS_API_KEY"]
flag :enable_releases, accept: String, default: ::ENV["ENABLE_RELEASES"]

include :exec, exit_on_nonzero_status: true
include :terminal, styled: true
include :fileutils
include "release-tools"

def run
  cd context_directory
  version = parse_ref release_ref
  puts "Releasing cloud_events #{version}...", :yellow, :bold
  verify_library_version version
  verify_changelog_content version
  using_api_key api_key do
    mkdir_p "pkg"
    built_file = "pkg/cloud_events-#{version}.gem"
    exec ["gem", "build", "cloud_events.gemspec", "-o", built_file]
    if /^t/i =~ enable_releases
      exec ["gem", "push", built_file]
      puts "SUCCESS: Released cloud_events #{version}", :green, :bold
    else
      error "#{built_file} didn't get built." unless ::File.file? built_file
      puts "SUCCESS: Mock release of cloud_events #{version}", :green, :bold
    end
  end
end

def parse_ref ref
  match = %r{^refs/tags/v(\d+\.\d+\.\d+)$}.match ref
  error "Illegal release ref: #{ref}" unless match
  match[1]
end

def using_api_key key
  home_dir = ::ENV["HOME"]
  creds_path = "#{home_dir}/.gem/credentials"
  creds_exist = ::File.exist? creds_path
  if creds_exist && !key
    puts "Using existing Rubygems credentials"
    yield
    return
  end
  error "API key not provided" unless key
  error "Cannot set API key because #{creds_path} already exists" if creds_exist
  begin
    mkdir_p "#{home_dir}/.gem"
    ::File.open creds_path, "w", 0o600 do |file|
      file.puts "---\n:rubygems_api_key: #{api_key}"
    end
    puts "Using provided Rubygems credentials"
    yield
  ensure
    exec ["shred", "-u", creds_path]
  end
end
