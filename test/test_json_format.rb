# frozen_string_literal: true

require_relative "helper"

require "base64"
require "date"
require "json"
require "stringio"
require "uri"

describe CloudEvents::JsonFormat do
  let(:json_format) { CloudEvents::JsonFormat.new }
  let(:my_id) { "my_id" }
  let(:my_source_string) { "/my_source" }
  let(:my_source) { URI.parse my_source_string }
  let(:my_type) { "my_type" }
  let(:my_json_data) { { "a" => 12_345, "b" => "hello", "c" => [true, false, nil] } }
  let(:my_json_string_data) { JSON.dump my_json_data }
  let(:my_data_string) { "12345" }
  let(:my_base64_data) { Base64.encode64 my_data_string }
  let(:my_content_encoding) { "8bit" }
  let(:my_content_type_string) { "text/plain; charset=us-ascii" }
  let(:my_content_type) { CloudEvents::ContentType.new my_content_type_string }
  let(:my_json_content_type_string) { "application/json; charset=us-ascii" }
  let(:my_json_content_type) { CloudEvents::ContentType.new my_json_content_type_string }
  let(:my_schema_string) { "/my_schema" }
  let(:my_schema) { URI.parse my_schema_string }
  let(:my_subject) { "my_subject" }
  let(:my_time_string) { "2020-01-12T20:52:05-08:00" }
  let(:my_time) { DateTime.rfc3339 my_time_string }
  let(:structured_content_type_string) { "application/cloudevents+json; charset=utf-8" }
  let(:structured_content_type) { CloudEvents::ContentType.new structured_content_type_string }
  let(:batched_content_type_string) { "application/cloudevents-batch+json; charset=utf-8" }
  let(:batched_content_type) { CloudEvents::ContentType.new batched_content_type_string }

  describe "v0" do
    let(:spec_version_v0) { "0.3" }
    let :my_json_struct_v0 do
      {
        "data"                => my_json_data,
        "datacontentencoding" => my_content_encoding,
        "datacontenttype"     => my_json_content_type_string,
        "id"                  => my_id,
        "schemaurl"           => my_schema_string,
        "source"              => my_source_string,
        "specversion"         => spec_version_v0,
        "subject"             => my_subject,
        "time"                => my_time_string,
        "type"                => my_type
      }
    end
    let :my_string_struct_v0 do
      {
        "data"                => my_data_string,
        "datacontentencoding" => my_content_encoding,
        "datacontenttype"     => my_content_type_string,
        "id"                  => my_id,
        "schemaurl"           => my_schema_string,
        "source"              => my_source_string,
        "specversion"         => spec_version_v0,
        "subject"             => my_subject,
        "time"                => my_time_string,
        "type"                => my_type
      }
    end
    let :my_json_string_struct_v0 do
      {
        "data"                => my_json_string_data,
        "datacontentencoding" => my_content_encoding,
        "datacontenttype"     => my_json_content_type_string,
        "id"                  => my_id,
        "schemaurl"           => my_schema_string,
        "source"              => my_source_string,
        "specversion"         => spec_version_v0,
        "subject"             => my_subject,
        "time"                => my_time_string,
        "type"                => my_type
      }
    end
    let(:my_json_struct_v0_string) { JSON.dump my_json_struct_v0 }
    let(:my_batch_v0_string) { JSON.dump [my_string_struct_v0, my_json_struct_v0] }

    it "decodes and encodes a struct with string data" do
      event = json_format.decode_hash_structure my_string_struct_v0
      assert_equal my_id, event.id
      assert_equal my_source, event.source
      assert_equal my_type, event.type
      assert_equal spec_version_v0, event.spec_version
      assert_equal my_data_string, event.data
      assert_equal my_content_encoding, event.data_content_encoding
      assert_equal my_content_type, event.data_content_type
      assert_equal my_schema, event.schema_url
      assert_equal my_subject, event.subject
      assert_equal my_time, event.time
      struct = json_format.encode_hash_structure event
      assert_equal my_string_struct_v0, struct
    end

    it "decodes and encodes a struct with json data" do
      event = json_format.decode_hash_structure my_json_struct_v0
      assert_equal my_id, event.id
      assert_equal my_source, event.source
      assert_equal my_type, event.type
      assert_equal spec_version_v0, event.spec_version
      assert_equal my_json_data, event.data
      assert_equal my_content_encoding, event.data_content_encoding
      assert_equal my_json_content_type, event.data_content_type
      assert_equal my_schema, event.schema_url
      assert_equal my_subject, event.subject
      assert_equal my_time, event.time
      struct = json_format.encode_hash_structure event
      assert_equal my_json_struct_v0, struct
    end

    it "decodes and encodes json-encoded content" do
      event = json_format.decode_event my_json_struct_v0_string, structured_content_type
      assert_equal my_id, event.id
      assert_equal my_source, event.source
      assert_equal my_type, event.type
      assert_equal spec_version_v0, event.spec_version
      assert_equal my_json_data, event.data
      assert_equal my_content_encoding, event.data_content_encoding
      assert_equal my_json_content_type, event.data_content_type
      assert_equal my_schema, event.schema_url
      assert_equal my_subject, event.subject
      assert_equal my_time, event.time
      string, content_type = json_format.encode_event event, sort: true
      assert_equal my_json_struct_v0_string, string
      assert_equal structured_content_type, content_type
    end

    it "decodes and encodes json-encoded batch" do
      events = json_format.decode_batch my_batch_v0_string, batched_content_type
      assert_equal 2, events.size
      event = events[0]
      assert_equal my_id, event.id
      assert_equal my_source, event.source
      assert_equal my_type, event.type
      assert_equal spec_version_v0, event.spec_version
      assert_equal my_data_string, event.data
      assert_equal my_content_encoding, event.data_content_encoding
      assert_equal my_content_type, event.data_content_type
      assert_equal my_schema, event.schema_url
      assert_equal my_subject, event.subject
      assert_equal my_time, event.time
      event = events[1]
      assert_equal my_id, event.id
      assert_equal my_source, event.source
      assert_equal my_type, event.type
      assert_equal spec_version_v0, event.spec_version
      assert_equal my_json_data, event.data
      assert_equal my_content_encoding, event.data_content_encoding
      assert_equal my_json_content_type, event.data_content_type
      assert_equal my_schema, event.schema_url
      assert_equal my_subject, event.subject
      assert_equal my_time, event.time
      string, content_type = json_format.encode_batch events, sort: true
      assert_equal my_batch_v0_string, string
      assert_equal batched_content_type, content_type
    end

    it "decodes json string data and expands the JSON" do
      event = json_format.decode_hash_structure my_json_string_struct_v0
      assert_equal my_json_data, event.data
    end

    it "encodes json string data and expands the JSON" do
      event = CloudEvents::Event::V0.new spec_version:      spec_version_v0,
                                         id:                my_id,
                                         source:            my_source_string,
                                         type:              my_type,
                                         data:              my_json_string_data,
                                         data_content_type: my_json_content_type_string
      struct = json_format.encode_hash_structure event
      assert_equal my_json_data, struct["data"]
    end

    it "refuses to decode non-json content types" do
      event = json_format.decode_event my_json_struct_v0_string, my_content_type
      assert_nil event
    end
  end

  describe "v1" do
    let(:spec_version_v1) { "1.0" }
    let :my_json_struct_v1 do
      {
        "data"            => my_json_data,
        "datacontenttype" => my_content_type_string,
        "dataschema"      => my_schema_string,
        "id"              => my_id,
        "source"          => my_source_string,
        "specversion"     => spec_version_v1,
        "subject"         => my_subject,
        "time"            => my_time_string,
        "type"            => my_type
      }
    end
    let :my_string_struct_v1 do
      {
        "data"            => my_data_string,
        "datacontenttype" => my_content_type_string,
        "dataschema"      => my_schema_string,
        "id"              => my_id,
        "source"          => my_source_string,
        "specversion"     => spec_version_v1,
        "subject"         => my_subject,
        "time"            => my_time_string,
        "type"            => my_type
      }
    end
    let :my_base64_struct_v1 do
      {
        "data_base64"     => my_base64_data,
        "datacontenttype" => my_content_type_string,
        "dataschema"      => my_schema_string,
        "id"              => my_id,
        "source"          => my_source_string,
        "specversion"     => spec_version_v1,
        "subject"         => my_subject,
        "time"            => my_time_string,
        "type"            => my_type
      }
    end
    let :my_incomplete_struct_v1 do
      {
        "data"            => my_json_data,
        "datacontenttype" => my_content_type_string,
        "dataschema"      => nil,
        "id"              => my_id,
        "source"          => my_source_string,
        "specversion"     => spec_version_v1,
        "time"            => nil,
        "type"            => my_type
      }
    end
    let(:my_json_struct_v1_string) { JSON.dump my_json_struct_v1 }
    let(:my_batch_v1_string) { JSON.dump [my_base64_struct_v1, my_json_struct_v1] }
    let :my_compacted_incomplete_struct_v1 do
      my_incomplete_struct_v1.delete_if { |_k, v| v.nil? }
    end

    it "decodes and encodes a struct with string data" do
      event = json_format.decode_hash_structure my_string_struct_v1
      assert_equal my_id, event.id
      assert_equal my_source, event.source
      assert_equal my_type, event.type
      assert_equal spec_version_v1, event.spec_version
      assert_equal my_data_string, event.data
      assert_equal my_content_type, event.data_content_type
      assert_equal my_schema, event.data_schema
      assert_equal my_subject, event.subject
      assert_equal my_time, event.time
      struct = json_format.encode_hash_structure event
      assert_equal my_string_struct_v1, struct
    end

    it "decodes and encodes a struct with base64 data" do
      event = json_format.decode_hash_structure my_base64_struct_v1
      assert_equal my_id, event.id
      assert_equal my_source, event.source
      assert_equal my_type, event.type
      assert_equal spec_version_v1, event.spec_version
      assert_equal my_data_string, event.data
      assert_equal my_content_type, event.data_content_type
      assert_equal my_schema, event.data_schema
      assert_equal my_subject, event.subject
      assert_equal my_time, event.time
      struct = json_format.encode_hash_structure event
      assert_equal my_base64_struct_v1, struct
    end

    it "decodes and encodes a struct with json data" do
      event = json_format.decode_hash_structure my_json_struct_v1
      assert_equal my_id, event.id
      assert_equal my_source, event.source
      assert_equal my_type, event.type
      assert_equal spec_version_v1, event.spec_version
      assert_equal my_json_data, event.data
      assert_equal my_content_type, event.data_content_type
      assert_equal my_schema, event.data_schema
      assert_equal my_subject, event.subject
      assert_equal my_time, event.time
      struct = json_format.encode_hash_structure event
      assert_equal my_json_struct_v1, struct
    end

    it "decodes and encodes json-encoded content" do
      event = json_format.decode_event my_json_struct_v1_string, structured_content_type
      assert_equal my_id, event.id
      assert_equal my_source, event.source
      assert_equal my_type, event.type
      assert_equal spec_version_v1, event.spec_version
      assert_equal my_json_data, event.data
      assert_equal my_content_type, event.data_content_type
      assert_equal my_schema, event.data_schema
      assert_equal my_subject, event.subject
      assert_equal my_time, event.time
      string, content_type = json_format.encode_event event, sort: true
      assert_equal my_json_struct_v1_string, string
      assert_equal structured_content_type, content_type
    end

    it "decodes and encodes json-encoded batch" do
      events = json_format.decode_batch my_batch_v1_string, batched_content_type
      assert_equal 2, events.size
      event = events[0]
      assert_equal my_id, event.id
      assert_equal my_source, event.source
      assert_equal my_type, event.type
      assert_equal spec_version_v1, event.spec_version
      assert_equal my_data_string, event.data
      assert_equal my_content_type, event.data_content_type
      assert_equal my_schema, event.data_schema
      assert_equal my_subject, event.subject
      assert_equal my_time, event.time
      event = events[1]
      assert_equal my_id, event.id
      assert_equal my_source, event.source
      assert_equal my_type, event.type
      assert_equal spec_version_v1, event.spec_version
      assert_equal my_json_data, event.data
      assert_equal my_content_type, event.data_content_type
      assert_equal my_schema, event.data_schema
      assert_equal my_subject, event.subject
      assert_equal my_time, event.time
      string, content_type = json_format.encode_batch events, sort: true
      assert_equal my_batch_v1_string, string
      assert_equal batched_content_type, content_type
    end

    it "decodes and encodes json with nulls" do
      event = json_format.decode_hash_structure my_incomplete_struct_v1
      assert_equal my_id, event.id
      assert_equal my_source, event.source
      assert_equal my_type, event.type
      assert_equal spec_version_v1, event.spec_version
      assert_equal my_json_data, event.data
      assert_equal my_content_type, event.data_content_type
      assert_nil event.data_schema
      assert_nil event.subject
      assert_nil event.time
      hash = event.to_h
      refute hash.include? "subject"
      refute hash.include? "time"
      struct = json_format.encode_hash_structure event
      assert_equal my_compacted_incomplete_struct_v1, struct
    end

    it "refuses to decode non-json content types" do
      event = json_format.decode_event my_json_struct_v1_string, my_content_type
      assert_nil event
    end

    it "raises SpecVersionError when JSON input has a bad specversion" do
      malformed_input = {
        "data"            => my_json_data,
        "datacontenttype" => my_content_type_string,
        "id"              => my_id,
        "source"          => my_source_string,
        "specversion"     => "0.1",
        "type"            => my_type
      }
      malformed_input_string = JSON.dump malformed_input
      assert_raises CloudEvents::SpecVersionError do
        json_format.decode_event malformed_input_string, structured_content_type
      end
    end

    it "raises AttributeError when JSON input is missing an ID" do
      malformed_input = {
        "data"            => my_json_data,
        "datacontenttype" => my_content_type_string,
        "source"          => my_source_string,
        "specversion"     => "1.0",
        "type"            => my_type
      }
      malformed_input_string = JSON.dump malformed_input
      assert_raises CloudEvents::AttributeError do
        json_format.decode_event malformed_input_string, structured_content_type
      end
    end

    it "raises FormatSyntaxError when decoding malformed JSON event" do
      error = assert_raises CloudEvents::FormatSyntaxError do
        json_format.decode_event "!!!", structured_content_type
      end
      assert_kind_of JSON::ParserError, error.cause
    end

    it "raises FormatSyntaxError when decoding malformed JSON batch" do
      error = assert_raises CloudEvents::FormatSyntaxError do
        json_format.decode_event "!!!", batched_content_type
      end
      assert_kind_of JSON::ParserError, error.cause
    end
  end

  describe "data conversion" do
    let(:my_json_string) { '{"foo":"bar"}' }
    let(:my_json_object) { { "foo" => "bar" } }

    it "decodes a JSON object" do
      obj, content_type = json_format.decode_data my_json_string, my_json_content_type
      assert_equal my_json_object, obj
      assert_equal my_json_content_type, content_type
    end

    it "raises FormatSyntaxError when decoding malformed JSON" do
      error = assert_raises CloudEvents::FormatSyntaxError do
        json_format.decode_data "!!!", my_json_content_type
      end
      assert_kind_of JSON::ParserError, error.cause
    end

    it "encodes a JSON object" do
      str, content_type = json_format.encode_data my_json_object, my_json_content_type
      assert_equal my_json_string, str
      assert_equal my_json_content_type, content_type
    end

    it "declines to decode when given a non-JSON content type" do
      assert_nil json_format.decode_data my_json_string, my_content_type
    end

    it "declines to encode when given a non-JSON content type" do
      assert_nil json_format.encode_data my_json_object, my_content_type
    end
  end
end
