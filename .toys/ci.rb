# frozen_string_literal: true

load_git remote: "https://github.com/dazuma/toys.git",
         path: "common-tools/ci",
         update: 3600

desc "Run all CI checks"

expand("toys-ci") do |toys_ci|
  toys_ci.only_flag = true
  toys_ci.fail_fast_flag = true
  toys_ci.job("Bundle update", flag: :bundle, exec: ["bundle", "update", "--all"])
  toys_ci.job("Rubocop", flag: :rubocop, tool: ["rubocop"])
  toys_ci.job("Tests", flag: :test, tool: ["test"])
  toys_ci.job("Cucumber", flag: :cucumber, tool: ["cucumber"])
  toys_ci.job("Yardoc", flag: :yard, tool: ["yardoc"])
  toys_ci.job("Gem build", flag: :build, tool: ["build"])
end
