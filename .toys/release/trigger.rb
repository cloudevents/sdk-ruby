# frozen_string_literal: true

desc "Trigger a release of cloud_events"

include :exec, exit_on_nonzero_status: true
include :terminal
include :fileutils
include "release-tools"

required_arg :version
flag :yes
flag :git_remote, default: "origin"

def run
  cd context_directory

  puts "Running prechecks...", :bold
  verify_git_clean
  verify_library_version version
  changelog_entry = verify_changelog_content version
  verify_github_checks

  puts "Found changelog entry:", :bold
  puts changelog_entry
  if !yes && !confirm("Release cloud_events #{version}?", :bold, default: true)
    error "Release aborted"
  end

  tag = "v#{version}"
  exec ["git", "tag", tag]
  exec ["git", "push", git_remote, tag]
  puts "SUCCESS: Pushed tag #{tag}", :green, :bold
end
