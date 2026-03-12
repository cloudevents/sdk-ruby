# frozen_string_literal: true

load_gem "toys-ci"

desc "CI target that runs CI jobs in this repo"

flag :bundle_update, "--update", "--bundle-update", desc: "Update instead of install bundles"

expand(Toys::CI::Template) do |ci|
  ci.only_flag = true
  ci.fail_fast_flag = true

  ci.job("Bundle install", flag: :bundle) do
    cmd = bundle_update ? ["bundle", "update", "--all"] : ["bundle", "install"]
    exec(cmd, name: "Bundle").success?
  end

  ci.tool_job("Rubocop", ["rubocop"], flag: :rubocop)
  ci.tool_job("Tests", ["test"], flag: :test)
  ci.tool_job("Cucumber", ["cucumber"], flag: :cucumber)
  ci.tool_job("Yardoc", ["yardoc"], flag: :yard)
  ci.tool_job("Gem build", ["build"], flag: :build)
end
