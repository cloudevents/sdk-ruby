# frozen_string_literal: true

require "minitest"

Minitest.load_plugins
Minitest::RG.rg! color: $stdout.tty?
