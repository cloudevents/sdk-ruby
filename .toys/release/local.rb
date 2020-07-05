# frozen_string_literal: true

desc "Builds and releases the gem from the local checkout"

required_arg :version
flag :dry_run, "--[no-]dry-run", default: false

include :exec, exit_on_nonzero_status: true
include :terminal
include "release-tools"

def run
  ::Dir.chdir context_directory

  verify_git_clean warn_only: true
  verify_library_version version, warn_only: true
  verify_changelog_content version, warn_only: true
  verify_github_checks warn_only: true

  puts "WARNING: You are releasing locally, outside the normal process!", :bold, :red
  unless confirm "Build and push gems for version #{version}? ", default: false
    error "Release aborted"
  end

  build_gem version
  push_gem version, dry_run: dry_run
end
