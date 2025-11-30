# frozen_string_literal: true

require "minitest"

module Minitest
  def self.plugin_rg_options opts, _options # :nodoc:
    opts.on "--[no-]rg", "Add red/green to test output." do |bool|
      RG.rg! color: bool
    end
  end

  def self.plugin_rg_init options # :nodoc:
    return unless RG.rg?

    io = RG.new options[:io]

    reporter.reporters.grep(Minitest::Reporter).each { |rep| rep.io = io }
  end

  class RG
    VERSION = "5.3.0"

    COLORS = {
      "." => "\e[32m.\e[0m",
      "E" => "\e[33mE\e[0m",
      "F" => "\e[31mF\e[0m",
      "S" => "\e[36mS\e[0m"
    }.freeze

    attr_reader :io, :colors

    def self.rg! color: true
      @rg = color
    end

    def self.rg?
      @rg ||= false
    end

    def initialize io, colors = COLORS
      @io     = io
      @colors = colors
    end

    def print output
      io.print(colors[output] || output)
    end

    def puts output = nil
      return io.puts if output.nil?

      if output =~ /(\d+) failures, (\d+) errors/
        if Regexp.last_match[1] != "0" || Regexp.last_match[2] != "0"
          io.puts "\e[31m#{output}\e[0m"
        else
          io.puts "\e[32m#{output}\e[0m"
        end
      else
        io.puts output
      end
    end

    def method_missing msg, *args
      return io.send(msg, *args) if io.respond_to? msg

      super
    end

    def respond_to_missing? method_name, include_all = false
      return true if io.respond_to? method_name, include_all

      super
    end
  end
end
