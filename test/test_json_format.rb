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
  let(:my_doubly_encoded_json_string_data) { JSON.dump my_json_string_data }
  let(:my_data_string) { "12345" }
  let(:my_json_encoded_data_string) { '"12345"' }
  let(:my_base64_data) { "/w==\n" }
  let(:my_binary_string) { Base64.decode64 my_base64_data }
  let(:my_content_encoding) { "8bit" }
  let(:my_content_type_string) { "text/plain; charset=us-ascii" }
  let(:my_content_type) { CloudEvents::ContentType.new my_content_type_string }
  let(:my_json_content_type_string) { "application/json; charset=us-ascii" }
  let(:my_json_content_type) { CloudEvents::ContentType.new my_json_content_type_string }
  let(:my_binary_content_type_string) { "application/octet-stream" }
  let(:my_binary_content_type) { CloudEvents::ContentType.new my_binary_content_type_string }
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
      result = json_format.decode_event content: my_json_struct_v0_string, content_type: structured_content_type
      event = result[:event]
      assert_kind_of CloudEvents::Event, event
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
      result = json_format.encode_event event: event, sort: true
      string = result[:content]
      content_type = result[:content_type]
      assert_equal my_json_struct_v0_string, string
      assert_equal structured_content_type, content_type
    end

    it "decodes and encodes json-encoded batch" do
      result = json_format.decode_event content: my_batch_v0_string, content_type: batched_content_type
      events = result[:event_batch]
      assert_kind_of Array, events
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
      result = json_format.encode_event event_batch: events, sort: true
      string = result[:content]
      content_type = result[:content_type]
      assert_equal my_batch_v0_string, string
      assert_equal batched_content_type, content_type
    end

    it "refuses to decode non-json content types" do
      assert_nil json_format.decode_event content: my_json_struct_v0_string, content_type: my_content_type
    end
  end

  describe "v1" do
    let(:spec_version_v1) { "1.0" }
    let :my_json_struct_v1 do
      {
        "data"            => my_json_data,
        "datacontenttype" => my_json_content_type_string,
        "dataschema"      => my_schema_string,
        "id"              => my_id,
        "source"          => my_source_string,
        "specversion"     => spec_version_v1,
        "subject"         => my_subject,
        "time"            => my_time_string,
        "type"            => my_type
      }
    end
    let :my_json_event_v1 do
      CloudEvents::Event::V1.new data: my_json_data,
                                 data_encoded: my_json_string_data,
                                 datacontenttype: my_json_content_type_string,
                                 dataschema: my_schema_string,
                                 id: my_id,
                                 source: my_source_string,
                                 specversion: spec_version_v1,
                                 subject: my_subject,
                                 time: my_time_string,
                                 type: my_type
    end
    let :my_json_string_struct_v1 do
      {
        "data"            => my_json_string_data,
        "datacontenttype" => my_json_content_type_string,
        "dataschema"      => my_schema_string,
        "id"              => my_id,
        "source"          => my_source_string,
        "specversion"     => spec_version_v1,
        "subject"         => my_subject,
        "time"            => my_time_string,
        "type"            => my_type
      }
    end
    let :my_json_string_event_v1 do
      CloudEvents::Event::V1.new data: my_json_string_data,
                                 data_encoded: my_doubly_encoded_json_string_data,
                                 datacontenttype: my_json_content_type_string,
                                 dataschema: my_schema_string,
                                 id: my_id,
                                 source: my_source_string,
                                 specversion: spec_version_v1,
                                 subject: my_subject,
                                 time: my_time_string,
                                 type: my_type
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
    let :my_string_event_v1 do
      CloudEvents::Event::V1.new data_encoded: my_data_string,
                                 datacontenttype: my_content_type_string,
                                 dataschema: my_schema_string,
                                 id: my_id,
                                 source: my_source_string,
                                 specversion: spec_version_v1,
                                 subject: my_subject,
                                 time: my_time_string,
                                 type: my_type
    end
    let :my_decoded_string_event_v1 do
      CloudEvents::Event::V1.new data_encoded: my_data_string,
                                 data: my_data_string,
                                 datacontenttype: my_content_type_string,
                                 dataschema: my_schema_string,
                                 id: my_id,
                                 source: my_source_string,
                                 specversion: spec_version_v1,
                                 subject: my_subject,
                                 time: my_time_string,
                                 type: my_type
    end
    let :my_nonencoded_string_event_v1 do
      CloudEvents::Event::V1.new data: my_data_string,
                                 datacontenttype: my_content_type_string,
                                 dataschema: my_schema_string,
                                 id: my_id,
                                 source: my_source_string,
                                 specversion: spec_version_v1,
                                 subject: my_subject,
                                 time: my_time_string,
                                 type: my_type
    end
    let :my_base64_struct_v1 do
      {
        "data_base64"     => my_base64_data,
        "datacontenttype" => my_binary_content_type_string,
        "dataschema"      => my_schema_string,
        "id"              => my_id,
        "source"          => my_source_string,
        "specversion"     => spec_version_v1,
        "subject"         => my_subject,
        "time"            => my_time_string,
        "type"            => my_type
      }
    end
    let :my_binary_event_v1 do
      CloudEvents::Event::V1.new data_encoded: my_binary_string,
                                 datacontenttype: my_binary_content_type_string,
                                 dataschema: my_schema_string,
                                 id: my_id,
                                 source: my_source_string,
                                 specversion: spec_version_v1,
                                 subject: my_subject,
                                 time: my_time_string,
                                 type: my_type
    end
    let :my_incomplete_struct_with_nils_v1 do
      {
        "data"            => my_json_data,
        "datacontenttype" => my_json_content_type_string,
        "dataschema"      => nil,
        "id"              => my_id,
        "source"          => my_source_string,
        "specversion"     => spec_version_v1,
        "time"            => nil,
        "type"            => my_type
      }
    end
    let :my_incomplete_struct_v1 do
      my_incomplete_struct_with_nils_v1.delete_if { |_k, v| v.nil? }
    end
    let :my_incomplete_event_v1 do
      CloudEvents::Event::V1.new data: my_json_data,
                                 data_encoded: my_json_string_data,
                                 datacontenttype: my_json_content_type_string,
                                 id: my_id,
                                 source: my_source_string,
                                 specversion: spec_version_v1,
                                 type: my_type
    end
    let :my_minimal_struct_v1 do
      {
        "id"              => my_id,
        "source"          => my_source_string,
        "specversion"     => spec_version_v1,
        "type"            => my_type
      }
    end
    let :my_minimal_event_v1 do
      CloudEvents::Event::V1.new id: my_id,
                                 source: my_source_string,
                                 specversion: spec_version_v1,
                                 type: my_type
    end
    let :my_typeless_struct_v1 do
      {
        "data"            => my_json_data,
        "dataschema"      => my_schema_string,
        "id"              => my_id,
        "source"          => my_source_string,
        "specversion"     => spec_version_v1,
        "subject"         => my_subject,
        "time"            => my_time_string,
        "type"            => my_type
      }
    end
    let(:my_json_struct_v1_string) { JSON.dump my_json_struct_v1 }
    let(:my_batch_v1_string) { JSON.dump [my_base64_struct_v1, my_json_struct_v1] }

    describe "decode_hash_structure" do
      it "decodes a struct with string data" do
        event = json_format.decode_hash_structure my_string_struct_v1
        assert_equal my_string_event_v1, event
        refute event.data_decoded?
      end

      it "decodes a struct with string data and a decoder" do
        text_decoder = CloudEvents::TextFormat.new
        event = json_format.decode_hash_structure my_string_struct_v1, data_decoder: text_decoder
        assert_equal my_decoded_string_event_v1, event
        assert event.data_decoded?
      end

      it "decodes a struct with base64 data" do
        event = json_format.decode_hash_structure my_base64_struct_v1
        assert_equal my_binary_event_v1, event
        refute event.data_decoded?
      end

      it "decodes a struct with json object data" do
        event = json_format.decode_hash_structure my_json_struct_v1
        assert_equal my_json_event_v1, event
        assert event.data_decoded?
      end

      it "decodes a struct with json string data" do
        event = json_format.decode_hash_structure my_json_string_struct_v1
        assert_equal my_json_string_event_v1, event
        assert event.data_decoded?
      end

      it "decodes a struct without content type" do
        event = json_format.decode_hash_structure my_typeless_struct_v1, charset: "us-ascii"
        assert_equal my_json_event_v1, event
        assert event.data_decoded?
        assert_equal my_json_content_type, event.data_content_type
      end

      it "decodes a struct with nulls" do
        event = json_format.decode_hash_structure my_incomplete_struct_with_nils_v1
        assert_equal my_incomplete_event_v1, event
        assert_nil event.data_schema
        assert_nil event.subject
        assert_nil event.time
        hash = event.to_h
        refute hash.include? "subject"
        refute hash.include? "time"
      end

      it "decodes a minimal struct" do
        event = json_format.decode_hash_structure my_minimal_struct_v1
        assert_equal my_minimal_event_v1, event
        refute event.data_decoded?
      end

      [
        "application/json",
        "text/json",
        "application/json; charset=utf-8",
        "application/blah+json",
        "application/blah+json; foo=bar"
      ].each do |content_type|
        it "recognizes #{content_type} as a json-object-data special case" do
          my_struct = my_minimal_struct_v1.merge(
            {
              "data" => my_json_string_data,
              "datacontenttype" => content_type
            }
          )
          event = json_format.decode_hash_structure my_struct
          assert_equal my_json_string_data, event.data
          assert_equal my_doubly_encoded_json_string_data, event.data_encoded
          assert event.data_decoded?
        end
      end
    end

    describe "encode_hash_structure" do
      it "encodes an event with string data" do
        struct = json_format.encode_hash_structure my_string_event_v1
        assert_equal my_string_struct_v1, struct
      end

      it "encodes an event with string data and an encoder" do
        text_encoder = CloudEvents::TextFormat.new
        struct = json_format.encode_hash_structure my_nonencoded_string_event_v1, data_encoder: text_encoder
        assert_equal my_string_struct_v1, struct
      end

      it "encodes an event with binary data" do
        struct = json_format.encode_hash_structure my_binary_event_v1
        assert_equal my_base64_struct_v1, struct
      end

      it "encodes an event with json object data" do
        struct = json_format.encode_hash_structure my_json_event_v1
        assert_equal my_json_struct_v1, struct
      end

      it "encodes an event with json string data" do
        struct = json_format.encode_hash_structure my_json_string_event_v1
        assert_equal my_json_string_struct_v1, struct
      end

      it "encodes an event without content type" do
        event = CloudEvents::Event.create spec_version: spec_version_v1,
                                          id:           my_id,
                                          source:       my_source,
                                          type:         my_type,
                                          data:         my_json_data
        struct = json_format.encode_hash_structure event
        assert_equal "application/json", struct["datacontenttype"]
      end

      it "encodes an event with nulls" do
        struct = json_format.encode_hash_structure my_incomplete_event_v1
        assert_equal my_incomplete_struct_v1, struct
      end

      it "encodes a minimal event" do
        struct = json_format.encode_hash_structure my_minimal_event_v1
        assert_equal my_minimal_struct_v1, struct
      end

      [
        "application/json",
        "text/json",
        "application/json; charset=utf-8",
        "application/blah+json",
        "application/blah+json; foo=bar"
      ].each do |content_type|
        it "encodes a string data value when content type is #{content_type}" do
          event = my_minimal_event_v1.with data: my_json_string_data, data_content_type: content_type
          struct = json_format.encode_hash_structure event
          assert_equal my_json_string_data, struct["data"]
        end

        it "encodes a data_encoded value when content type is #{content_type}" do
          event = my_minimal_event_v1.with data_encoded: my_doubly_encoded_json_string_data,
                                           data_content_type: content_type
          struct = json_format.encode_hash_structure event
          assert_equal my_json_string_data, struct["data"]
        end
      end
    end

    describe "decode_event" do
      it "decodes a single event" do
        result = json_format.decode_event content: my_json_struct_v1_string, content_type: structured_content_type
        assert_equal my_json_event_v1, result[:event]
      end

      it "decodes a batch event" do
        result = json_format.decode_event content: my_batch_v1_string, content_type: batched_content_type
        assert_equal [my_binary_event_v1, my_json_event_v1], result[:event_batch]
      end

      it "refuses to decode non-json content types" do
        assert_nil json_format.decode_event content: my_json_struct_v1_string, content_type: my_content_type
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
          json_format.decode_event content: malformed_input_string, content_type: structured_content_type
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
          json_format.decode_event content: malformed_input_string, content_type: structured_content_type
        end
      end

      it "raises FormatSyntaxError when decoding malformed JSON event" do
        error = assert_raises CloudEvents::FormatSyntaxError do
          json_format.decode_event content: "!!!", content_type: structured_content_type
        end
        assert_kind_of JSON::ParserError, error.cause
      end

      it "raises FormatSyntaxError when decoding malformed JSON batch" do
        error = assert_raises CloudEvents::FormatSyntaxError do
          json_format.decode_event content: "!!!", content_type: batched_content_type
        end
        assert_kind_of JSON::ParserError, error.cause
      end
    end

    describe "encode_event" do
      it "encodes a single event" do
        result = json_format.encode_event event: my_json_event_v1, sort: true
        assert_equal my_json_struct_v1_string, result[:content]
        assert_equal structured_content_type, result[:content_type]
      end

      it "encodes a batch event" do
        result = json_format.encode_event event_batch: [my_binary_event_v1, my_json_event_v1], sort: true
        assert_equal my_batch_v1_string, result[:content]
        assert_equal batched_content_type, result[:content_type]
      end

      it "raises UnsupportedFormatError on missing data_encoded and an unrecognized media type" do
        event = my_string_event_v1.with data: "hello", data_content_type: "application/blah"
        assert_raises CloudEvents::UnsupportedFormatError do
          json_format.encode_event event: event, sort: true
        end
      end
    end
  end

  describe "data conversion" do
    let(:my_json_string) { '{"foo":"bar"}' }
    let(:my_json_object) { { "foo" => "bar" } }
    let(:spec_version_1) { "1.0" }

    it "decodes a JSON object" do
      result = json_format.decode_data spec_version: spec_version_1,
                                       content: my_json_string,
                                       content_type: my_json_content_type
      obj = result[:data]
      content_type = result[:content_type]
      assert_equal my_json_object, obj
      assert_equal my_json_content_type, content_type
    end

    it "raises FormatSyntaxError when decoding malformed JSON" do
      error = assert_raises CloudEvents::FormatSyntaxError do
        json_format.decode_data spec_version: spec_version_1,
                                content: "!!!",
                                content_type: my_json_content_type
      end
      assert_kind_of JSON::ParserError, error.cause
    end

    it "encodes a JSON object" do
      result = json_format.encode_data spec_version: spec_version_1,
                                       data: my_json_object,
                                       content_type: my_json_content_type
      str = result[:content]
      content_type = result[:content_type]
      assert_equal my_json_string, str
      assert_equal my_json_content_type, content_type
    end

    it "declines to decode when given a non-JSON content type" do
      assert_nil json_format.decode_data spec_version: spec_version_1,
                                         content: my_json_string,
                                         content_type: my_content_type
    end

    it "declines to encode when given a non-JSON content type" do
      assert_nil json_format.encode_data spec_version: spec_version_1,
                                         data: my_json_object,
                                         content_type: my_content_type
    end
  end
end
