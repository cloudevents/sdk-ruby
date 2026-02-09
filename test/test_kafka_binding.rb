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

  describe "decode_event structured mode" do
    let(:my_json_struct) do
      {
        "data" => my_simple_data,
        "datacontenttype" => my_content_type_string,
        "dataschema" => my_schema_string,
        "id" => my_id,
        "source" => my_source_string,
        "specversion" => spec_version,
        "subject" => my_subject,
        "time" => my_time_string,
        "type" => my_type,
      }
    end
    let(:my_json_struct_encoded) { JSON.dump(my_json_struct) }

    it "decodes a JSON-structured message" do
      message = {
        key: nil,
        value: my_json_struct_encoded,
        headers: { "content-type" => "application/cloudevents+json" },
      }
      event = kafka_binding.decode_event(message, reverse_key_mapper: nil)
      assert_equal my_id, event.id
      assert_equal my_source, event.source
      assert_equal my_type, event.type
      assert_equal spec_version, event.spec_version
      assert_equal my_simple_data, event.data
    end

    it "decodes a JSON-structured message with charset" do
      message = {
        key: nil,
        value: my_json_struct_encoded,
        headers: { "content-type" => "application/cloudevents+json; charset=utf-8" },
      }
      event = kafka_binding.decode_event(message, reverse_key_mapper: nil)
      assert_equal my_id, event.id
      assert_equal my_type, event.type
    end

    it "returns opaque for unrecognized structured format when allow_opaque is true" do
      message = {
        key: nil,
        value: "some content",
        headers: { "content-type" => "application/cloudevents+foo" },
      }
      event = minimal_kafka_binding.decode_event(message, allow_opaque: true, reverse_key_mapper: nil)
      assert_kind_of CloudEvents::Event::Opaque, event
      assert_equal "some content", event.content
    end

    it "raises UnsupportedFormatError for unknown structured format" do
      message = {
        key: nil,
        value: "some content",
        headers: { "content-type" => "application/cloudevents+foo" },
      }
      assert_raises CloudEvents::UnsupportedFormatError do
        kafka_binding.decode_event(message, reverse_key_mapper: nil)
      end
    end

    it "raises FormatSyntaxError for malformed JSON" do
      message = {
        key: nil,
        value: "!!!",
        headers: { "content-type" => "application/cloudevents+json" },
      }
      error = assert_raises(CloudEvents::FormatSyntaxError) do
        kafka_binding.decode_event(message, reverse_key_mapper: nil)
      end
      assert_kind_of JSON::ParserError, error.cause
    end

    it "applies reverse_key_mapper to structured decoded events" do
      message = {
        key: "my-partition-key",
        value: my_json_struct_encoded,
        headers: { "content-type" => "application/cloudevents+json" },
      }
      event = kafka_binding.decode_event(message)
      assert_equal "my-partition-key", event["partitionkey"]
    end
  end

  describe "encode_event binary mode" do
    let(:my_simple_event) do
      CloudEvents::Event::V1.new(data_encoded: my_simple_data,
                                 data: my_simple_data,
                                 datacontenttype: my_content_type_string,
                                 dataschema: my_schema_string,
                                 id: my_id,
                                 source: my_source_string,
                                 specversion: spec_version,
                                 subject: my_subject,
                                 time: my_time_string,
                                 type: my_type)
    end
    let(:my_json_event) do
      CloudEvents::Event::V1.new(data_encoded: my_json_escaped_data,
                                 data: my_json_object,
                                 datacontenttype: my_json_content_type_string,
                                 dataschema: my_schema_string,
                                 id: my_id,
                                 source: my_source_string,
                                 specversion: spec_version,
                                 subject: my_subject,
                                 time: my_time_string,
                                 type: my_type)
    end
    let(:my_minimal_event) do
      CloudEvents::Event::V1.new(id: my_id,
                                 source: my_source_string,
                                 specversion: spec_version,
                                 type: my_type)
    end
    let(:my_extensions_event) do
      CloudEvents::Event::V1.new(data_encoded: my_simple_data,
                                 data: my_simple_data,
                                 datacontenttype: my_content_type_string,
                                 id: my_id,
                                 source: my_source_string,
                                 specversion: spec_version,
                                 type: my_type,
                                 tracecontext: my_trace_context)
    end

    it "encodes an event with text content type to binary mode" do
      message = kafka_binding.encode_event(my_simple_event, key_mapper: nil)
      assert_equal my_simple_data, message[:value]
      assert_equal my_content_type_string, message[:headers]["content-type"]
      assert_equal spec_version, message[:headers]["ce_specversion"]
      assert_equal my_id, message[:headers]["ce_id"]
      assert_equal my_source_string, message[:headers]["ce_source"]
      assert_equal my_type, message[:headers]["ce_type"]
      assert_equal my_schema_string, message[:headers]["ce_dataschema"]
      assert_equal my_subject, message[:headers]["ce_subject"]
      assert_equal my_time_string, message[:headers]["ce_time"]
      assert_nil message[:key]
    end

    it "encodes an event with JSON content type to binary mode" do
      message = kafka_binding.encode_event(my_json_event, key_mapper: nil)
      assert_equal my_json_escaped_data, message[:value]
      assert_equal my_json_content_type_string, message[:headers]["content-type"]
    end

    it "encodes a minimal event" do
      message = kafka_binding.encode_event(my_minimal_event, key_mapper: nil)
      assert_nil message[:value]
      assert_nil message[:headers]["content-type"]
      assert_equal spec_version, message[:headers]["ce_specversion"]
      assert_equal my_id, message[:headers]["ce_id"]
    end

    it "encodes an event with extension attributes" do
      message = kafka_binding.encode_event(my_extensions_event, key_mapper: nil)
      assert_equal my_trace_context, message[:headers]["ce_tracecontext"]
    end

    it "encodes an event with no data as tombstone (nil value)" do
      message = kafka_binding.encode_event(my_minimal_event, key_mapper: nil)
      assert_nil message[:value]
    end

    it "uses default key_mapper to set key from partitionkey" do
      event = my_simple_event.with(partitionkey: "my-partition-key")
      message = kafka_binding.encode_event(event)
      assert_equal "my-partition-key", message[:key]
    end

    it "produces nil key when event has no partitionkey" do
      message = kafka_binding.encode_event(my_simple_event)
      assert_nil message[:key]
    end

    it "uses custom key_mapper per-call" do
      message = kafka_binding.encode_event(my_simple_event, key_mapper: :id.to_proc)
      assert_equal my_id, message[:key]
    end

    it "produces nil key when key_mapper is nil" do
      event = my_simple_event.with(partitionkey: "my-partition-key")
      message = kafka_binding.encode_event(event, key_mapper: nil)
      assert_nil message[:key]
    end
  end

  describe "encode_event structured mode" do
    let(:my_simple_event) do
      CloudEvents::Event::V1.new(data_encoded: my_simple_data,
                                 data: my_simple_data,
                                 datacontenttype: my_content_type_string,
                                 dataschema: my_schema_string,
                                 id: my_id,
                                 source: my_source_string,
                                 specversion: spec_version,
                                 subject: my_subject,
                                 time: my_time_string,
                                 type: my_type)
    end

    it "encodes an event to JSON structured format" do
      message = kafka_binding.encode_event(my_simple_event, structured_format: true,
                                                            key_mapper: nil, sort: true)
      assert_equal "application/cloudevents+json; charset=utf-8", message[:headers]["content-type"]
      parsed = JSON.parse(message[:value])
      assert_equal my_id, parsed["id"]
      assert_equal my_type, parsed["type"]
      assert_equal my_source_string, parsed["source"]
      assert_nil message[:key]
    end

    it "encodes an opaque event" do
      opaque = CloudEvents::Event::Opaque.new("some content",
                                              CloudEvents::ContentType.new("application/cloudevents+json"))
      message = kafka_binding.encode_event(opaque)
      assert_equal "some content", message[:value]
      assert_equal "application/cloudevents+json", message[:headers]["content-type"]
      assert_nil message[:key]
    end

    it "applies key_mapper in structured mode" do
      event = my_simple_event.with(partitionkey: "my-partition-key")
      message = kafka_binding.encode_event(event, structured_format: true)
      assert_equal "my-partition-key", message[:key]
    end

    it "raises ArgumentError when format name not specified and no default" do
      binding_obj = CloudEvents::KafkaBinding.new
      assert_raises ::ArgumentError do
        binding_obj.encode_event(my_simple_event, structured_format: true, key_mapper: nil)
      end
    end
  end

  describe "round-trip" do
    let(:my_event) do
      CloudEvents::Event::V1.new(data_encoded: my_json_escaped_data,
                                 data: my_json_object,
                                 datacontenttype: my_json_content_type_string,
                                 dataschema: my_schema_string,
                                 id: my_id,
                                 source: my_source_string,
                                 specversion: spec_version,
                                 subject: my_subject,
                                 time: my_time_string,
                                 type: my_type)
    end

    it "round-trips through binary mode" do
      message = kafka_binding.encode_event(my_event, key_mapper: nil)
      decoded = kafka_binding.decode_event(message, reverse_key_mapper: nil)
      assert_equal my_event, decoded
    end

    it "round-trips through structured mode" do
      message = kafka_binding.encode_event(my_event, structured_format: true, key_mapper: nil, sort: true)
      decoded = kafka_binding.decode_event(message, reverse_key_mapper: nil)
      assert_equal my_event, decoded
    end

    it "round-trips with partitionkey extension" do
      event = my_event.with(partitionkey: "my-partition-key")
      message = kafka_binding.encode_event(event)
      decoded = kafka_binding.decode_event(message)
      assert_equal event, decoded
    end
  end
end
