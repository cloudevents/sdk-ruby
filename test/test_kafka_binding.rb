# frozen_string_literal: true

require_relative "helper"

require "date"
require "json"
require "uri"

describe CloudEvents::KafkaBinding do
  let(:kafka_binding) { CloudEvents::KafkaBinding.default }
  let(:minimal_kafka_binding) { CloudEvents::KafkaBinding.new }
  let(:my_id) { "my_id" }
  let(:my_source_string) { "/my_source" }
  let(:my_source) { URI.parse(my_source_string) }
  let(:my_type) { "my_type" }
  let(:spec_version) { "1.0" }
  let(:my_simple_data) { "12345" }
  let(:my_json_object) { { "a" => "ä", "b" => "😀" } }
  let(:my_json_escaped_data) { '{"a":"ä","b":"😀"}' }
  let(:my_content_type_string) { "text/plain; charset=us-ascii" }
  let(:my_content_type) { CloudEvents::ContentType.new(my_content_type_string) }
  let(:my_json_content_type_string) { "application/json" }
  let(:my_json_content_type) { CloudEvents::ContentType.new(my_json_content_type_string) }
  let(:my_schema_string) { "/my_schema" }
  let(:my_schema) { URI.parse(my_schema_string) }
  let(:my_subject) { "my_subject" }
  let(:my_time_string) { "2020-01-12T20:52:05-08:00" }
  let(:my_time) { DateTime.rfc3339(my_time_string) }
  let(:my_trace_context) { "1234567890;9876543210" }

  describe "constructor" do
    it "creates a new instance" do
      binding_obj = CloudEvents::KafkaBinding.new
      assert_instance_of CloudEvents::KafkaBinding, binding_obj
    end

    it "returns a default instance with JSON format registered" do
      assert_instance_of CloudEvents::KafkaBinding, kafka_binding
    end

    it "returns the same default singleton" do
      assert_same CloudEvents::KafkaBinding.default, CloudEvents::KafkaBinding.default
    end

    it "defines DEFAULT_KEY_MAPPER constant" do
      assert_respond_to CloudEvents::KafkaBinding::DEFAULT_KEY_MAPPER, :call
    end

    it "defines DEFAULT_REVERSE_KEY_MAPPER constant" do
      assert_respond_to CloudEvents::KafkaBinding::DEFAULT_REVERSE_KEY_MAPPER, :call
    end
  end
end
