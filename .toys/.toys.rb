# frozen_string_literal: true

toys_version! ">= 0.16"

expand :clean, paths: :gitignore

expand :minitest, libs: ["lib"], bundler: true

expand :rubocop, bundler: true

expand :yardoc do |t|
  t.generate_output_flag = true
  t.fail_on_warning = true
  t.fail_on_undocumented_objects = true
  t.use_bundler
end

expand :gem_build

expand :gem_build, name: "install", install_gem: true

load_git remote: "https://github.com/dazuma/toys.git",
         commit: "common-tools/v0.17.0",
         path: "common-tools/release",
         as: "release"
