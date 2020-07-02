# frozen_string_literal: true

expand :clean, paths: ["pkg", "doc", ".yardoc", "tmp"]

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

mixin "release-tools" do
  on_include do
    include :terminal unless include? :terminal
  end

  def verify_library_version vers
    require "#{context_directory}/lib/cloud_events/version.rb"
    lib_vers = ::CloudEvents::VERSION
    unless vers == lib_vers
      error "Tagged version #{vers.inspect} doesn't match library version #{lib_vers.inspect}.",
            "Modify lib/functions_framework/version.rb and set VERSION = #{vers.inspect}"
    end
    vers
  end

  def verify_changelog_content vers
    today = ::Time.now.strftime "%Y-%m-%d"
    entry = []
    state = :start
    ::File.readlines("#{context_directory}/CHANGELOG.md").each do |line|
      case state
      when :start
        if line =~ /^### v#{::Regexp.escape(vers)} \/ \d\d\d\d-\d\d-\d\d\n$/
          entry << line
          state = :during
        elsif line =~ /^### /
          error "First changelog entry isn't for version #{vers}",
                "It should start with:",
                "### v#{vers} / #{today}",
                "But it actually starts with:",
                line
        end
      when :during
        if line =~ /^### /
          state = :after
        else
          entry << line
        end
      end
    end
    if entry.empty?
      error "Changelog doesn't have any entries.",
            "The first changelog entry should start with:",
            "### v#{vers} / #{today}"
    end
    entry.join
  end

  def error message, *more_messages
    puts message, :red, :bold
    more_messages.each { |m| puts m }
    exit 1
  end
end
