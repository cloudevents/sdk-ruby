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

  describe "probable_event?" do
    it "detects a probable binary event" do
      message = {
        key: nil,
        value: "hello",
        headers: { "ce_specversion" => "1.0" },
      }
      assert kafka_binding.probable_event?(message)
    end

    it "detects a probable structured event" do
      message = {
        key: nil,
        value: "{}",
        headers: { "content-type" => "application/cloudevents+json" },
      }
      assert kafka_binding.probable_event?(message)
    end

    it "returns false for a non-CE message" do
      message = {
        key: nil,
        value: "hello",
        headers: { "content-type" => "application/json" },
      }
      refute kafka_binding.probable_event?(message)
    end

    it "returns false for a message with no relevant headers" do
      message = {
        key: nil,
        value: "hello",
        headers: {},
      }
      refute kafka_binding.probable_event?(message)
    end
  end

  describe "decode_event binary mode" do
    it "decodes a binary message with text content type" do
      message = {
        key: nil,
        value: my_simple_data,
        headers: {
          "ce_specversion" => spec_version,
          "ce_id" => my_id,
          "ce_source" => my_source_string,
          "ce_type" => my_type,
          "content-type" => my_content_type_string,
          "ce_dataschema" => my_schema_string,
          "ce_subject" => my_subject,
          "ce_time" => my_time_string,
        },
      }
      event = kafka_binding.decode_event(message, reverse_key_mapper: nil)
      assert_equal my_id, event.id
      assert_equal my_source, event.source
      assert_equal my_type, event.type
      assert_equal spec_version, event.spec_version
      assert_equal my_simple_data, event.data
      assert_equal my_content_type_string, event.data_content_type.to_s
      assert_equal my_schema, event.data_schema
      assert_equal my_subject, event.subject
      assert_equal my_time, event.time
    end

    it "decodes a binary message with JSON content type" do
      message = {
        key: nil,
        value: my_json_escaped_data,
        headers: {
          "ce_specversion" => spec_version,
          "ce_id" => my_id,
          "ce_source" => my_source_string,
          "ce_type" => my_type,
          "content-type" => my_json_content_type_string,
          "ce_dataschema" => my_schema_string,
          "ce_subject" => my_subject,
          "ce_time" => my_time_string,
        },
      }
      event = kafka_binding.decode_event(message, reverse_key_mapper: nil)
      assert_equal my_json_object, event.data
      assert_equal my_json_escaped_data, event.data_encoded
    end

    it "decodes a minimal binary message" do
      message = {
        key: nil,
        value: nil,
        headers: {
          "ce_specversion" => spec_version,
          "ce_id" => my_id,
          "ce_source" => my_source_string,
          "ce_type" => my_type,
        },
      }
      event = kafka_binding.decode_event(message, reverse_key_mapper: nil)
      assert_equal my_id, event.id
      assert_equal my_source, event.source
      assert_equal my_type, event.type
      assert_nil event.data
      assert_nil event.data_content_type
    end

    it "decodes a binary message with extension attributes" do
      message = {
        key: nil,
        value: my_simple_data,
        headers: {
          "ce_specversion" => spec_version,
          "ce_id" => my_id,
          "ce_source" => my_source_string,
          "ce_type" => my_type,
          "content-type" => my_content_type_string,
          "ce_tracecontext" => my_trace_context,
        },
      }
      event = kafka_binding.decode_event(message, reverse_key_mapper: nil)
      assert_equal my_trace_context, event["tracecontext"]
    end

    it "decodes a tombstone message (nil value)" do
      message = {
        key: nil,
        value: nil,
        headers: {
          "ce_specversion" => spec_version,
          "ce_id" => my_id,
          "ce_source" => my_source_string,
          "ce_type" => my_type,
        },
      }
      event = kafka_binding.decode_event(message, reverse_key_mapper: nil)
      refute event.data?
      assert_nil event.data
    end

    it "maps key to partitionkey with default reverse_key_mapper" do
      message = {
        key: "my-partition-key",
        value: my_simple_data,
        headers: {
          "ce_specversion" => spec_version,
          "ce_id" => my_id,
          "ce_source" => my_source_string,
          "ce_type" => my_type,
          "content-type" => my_content_type_string,
        },
      }
      event = kafka_binding.decode_event(message)
      assert_equal "my-partition-key", event["partitionkey"]
    end

    it "uses custom reverse_key_mapper per-call" do
      message = {
        key: "custom-key",
        value: my_simple_data,
        headers: {
          "ce_specversion" => spec_version,
          "ce_id" => my_id,
          "ce_source" => my_source_string,
          "ce_type" => my_type,
          "content-type" => my_content_type_string,
        },
      }
      mapper = ->(key) { key.nil? ? {} : { "mykey" => key } }
      event = kafka_binding.decode_event(message, reverse_key_mapper: mapper)
      assert_equal "custom-key", event["mykey"]
      assert_nil event["partitionkey"]
    end

    it "skips key mapping when reverse_key_mapper is nil" do
      message = {
        key: "my-partition-key",
        value: my_simple_data,
        headers: {
          "ce_specversion" => spec_version,
          "ce_id" => my_id,
          "ce_source" => my_source_string,
          "ce_type" => my_type,
          "content-type" => my_content_type_string,
        },
      }
      event = kafka_binding.decode_event(message, reverse_key_mapper: nil)
      assert_nil event["partitionkey"]
    end

    it "raises SpecVersionError for bad specversion" do
      message = {
        key: nil,
        value: "hello",
        headers: {
          "ce_specversion" => "0.1",
          "ce_id" => my_id,
          "ce_source" => my_source_string,
          "ce_type" => my_type,
        },
      }
      assert_raises CloudEvents::SpecVersionError do
        kafka_binding.decode_event(message, reverse_key_mapper: nil)
      end
    end

    it "raises NotCloudEventError for non-CE message" do
      message = {
        key: nil,
        value: "hello",
        headers: { "content-type" => "application/json" },
      }
      assert_raises CloudEvents::NotCloudEventError do
        kafka_binding.decode_event(message, reverse_key_mapper: nil)
      end
    end
  end
end
