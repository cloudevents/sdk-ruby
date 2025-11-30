# frozen_string_literal: true

# -*- ruby -*-

require "rubygems"
require "hoe"

Hoe.plugin :gemspec  # `gem install hoe-gemspec`
Hoe.plugin :git      # `gem install hoe-git`
Hoe.plugin :minitest # `gem install hoe-minitest`

Hoe.spec "minitest-rg" do
  developer "Mike Moore", "mike@blowmage.com"

  self.summary     = "Red/Green for Minitest"
  self.description = "Colored red/green output for Minitest"
  license "MIT"

  self.readme_file       = "README.rdoc"
  self.history_file      = "CHANGELOG.rdoc"

  dependency "minitest",  "~> 5.0"
  dependency "rubocop",   "~> 1.57.0", :dev
end

# vim: syntax=ruby

desc "Run all test type scripts"
task :sanity do
  puts "="*72
  puts "Running a \e[32mpassing\e[0m test:"
  puts "="*72
  puts
  puts capture_output("pass")
  puts

  puts "="*72
  puts "Running a \e[31mfailing\e[0m test:"
  puts "="*72
  puts
  puts capture_output("fail")
  puts

  puts "="*72
  puts "Running a \e[33merroring\e[0m test:"
  puts "="*72
  puts
  puts capture_output("error")
  puts

  puts "="*72
  puts "Running a \e[36mskipped\e[0m test:"
  puts "="*72
  puts
  puts capture_output("skip")
  puts
end

def capture_output command
  os = `uname -s`.chomp
  if os.include?("BSD") || os.include?("Darwin")
    `script -q /dev/null ./scripts/run_#{command}`
  else
    `script -q -c ./scripts/run_#{command} /dev/null`
  end
end

require "rubocop/rake_task"

RuboCop::RakeTask.new
