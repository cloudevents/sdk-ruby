$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "cloudevents"

require "minitest/autorun"
require "minitest/spec"
require "rack"

alias context describe
