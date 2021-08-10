# frozen_string_literal: true

desc "Run all CI checks"

include :exec, result_callback: :handle_result
include :terminal

def handle_result result
  if result.success?
    puts "** #{result.name} passed\n\n", :green, :bold
  else
    puts "** CI terminated: #{result.name} failed!", :red, :bold
    exit 1
  end
end

def run
  ::Dir.chdir context_directory
  exec_tool ["test"], name: "Tests"
  exec_tool ["cucumber"], name: "Behaviors"
  exec_tool ["rubocop"], name: "Style checker"
  exec_tool ["yardoc"], name: "Docs generation"
  exec_tool ["build"], name: "Gem build"
end
