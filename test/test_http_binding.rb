# frozen_string_literal: true

require_relative "helper"

require "date"
require "json"
require "stringio"
require "uri"

describe CloudEvents::HttpBinding do
  let(:http_binding) { CloudEvents::HttpBinding.default }
  let(:minimal_http_binding) { CloudEvents::HttpBinding.new }
  let(:my_id) { "my_id" }
  let(:my_source_string) { "/my_source" }
  let(:my_source) { URI.parse(my_source_string) }
  let(:my_type) { "my_type" }
  let(:weird_type) { "¡Hola!\n\"100%\" 😀 " }
  let(:encoded_weird_type) { "%C2%A1Hola!%0A%22100%25%22%20%F0%9F%98%80%20" }
  let(:quoted_type) { "Hello Ruby world this\"is\\a1string okay" }
  let(:encoded_quoted_type) { "Hello%20\"Ruby%20world\"%20\"this\\\"is\\\\a\\1string\"%20okay" }
  let(:spec_version) { "1.0" }
  let(:my_simple_data) { "12345" }
  let(:my_json_escaped_simple_data) { '"12345"' }
  let(:my_content_type_string) { "text/plain; charset=us-ascii" }
  let(:my_content_type) { CloudEvents::ContentType.new(my_content_type_string) }
  let(:my_json_content_type_string) { "application/json; charset=us-ascii" }
  let(:my_json_content_type) { CloudEvents::ContentType.new(my_json_content_type_string) }
  let(:my_schema_string) { "/my_schema" }
  let(:my_schema) { URI.parse(my_schema_string) }
  let(:my_subject) { "my_subject" }
  let(:my_time_string) { "2020-01-12T20:52:05-08:00" }
  let(:my_time) { DateTime.rfc3339(my_time_string) }
  let(:my_trace_context) { "1234567890;9876543210" }
  let :my_json_struct do
    {
      "data"            => my_simple_data,
      "datacontenttype" => my_content_type_string,
      "dataschema"      => my_schema_string,
      "id"              => my_id,
      "source"          => my_source_string,
      "specversion"     => spec_version,
      "subject"         => my_subject,
      "time"            => my_time_string,
      "type"            => my_type,
    }
  end
  let(:my_json_struct_encoded) { JSON.dump(my_json_struct) }
  let(:my_json_batch_encoded) { JSON.dump([my_json_struct]) }
  let :my_json_data_struct do
    {
      "data"            => my_simple_data,
      "datacontenttype" => my_json_content_type_string,
      "dataschema"      => my_schema_string,
      "id"              => my_id,
      "source"          => my_source_string,
      "specversion"     => spec_version,
      "subject"         => my_subject,
      "time"            => my_time_string,
      "type"            => my_type,
    }
  end
  let(:my_json_data_struct_encoded) { JSON.dump(my_json_data_struct) }
  let :my_simple_binary_mode do
    {
      "rack.input"          => StringIO.new(my_simple_data),
      "HTTP_CE_ID"          => my_id,
      "HTTP_CE_SOURCE"      => my_source_string,
      "HTTP_CE_TYPE"        => my_type,
      "HTTP_CE_SPECVERSION" => spec_version,
      "CONTENT_TYPE"        => my_content_type_string,
      "HTTP_CE_DATASCHEMA"  => my_schema_string,
      "HTTP_CE_SUBJECT"     => my_subject,
      "HTTP_CE_TIME"        => my_time_string,
    }
  end
  let :my_json_binary_mode do
    {
      "rack.input"          => StringIO.new(my_json_escaped_simple_data),
      "HTTP_CE_ID"          => my_id,
      "HTTP_CE_SOURCE"      => my_source_string,
      "HTTP_CE_TYPE"        => my_type,
      "HTTP_CE_SPECVERSION" => spec_version,
      "CONTENT_TYPE"        => my_json_content_type_string,
      "HTTP_CE_DATASCHEMA"  => my_schema_string,
      "HTTP_CE_SUBJECT"     => my_subject,
      "HTTP_CE_TIME"        => my_time_string,
    }
  end
  let :my_minimal_binary_mode do
    {
      "rack.input"          => StringIO.new(""),
      "HTTP_CE_ID"          => my_id,
      "HTTP_CE_SOURCE"      => my_source_string,
      "HTTP_CE_TYPE"        => my_type,
      "HTTP_CE_SPECVERSION" => spec_version,
    }
  end
  let :my_extensions_binary_mode do
    {
      "rack.input"           => StringIO.new(my_simple_data),
      "HTTP_CE_ID"           => my_id,
      "HTTP_CE_SOURCE"       => my_source_string,
      "HTTP_CE_TYPE"         => my_type,
      "HTTP_CE_SPECVERSION"  => spec_version,
      "CONTENT_TYPE"         => my_content_type_string,
      "HTTP_CE_DATASCHEMA"   => my_schema_string,
      "HTTP_CE_SUBJECT"      => my_subject,
      "HTTP_CE_TIME"         => my_time_string,
      "HTTP_CE_TRACECONTEXT" => my_trace_context,
    }
  end
  let :my_nonascii_binary_mode do
    {
      "rack.input"          => StringIO.new(my_simple_data),
      "HTTP_CE_ID"          => my_id,
      "HTTP_CE_SOURCE"      => my_source_string,
      "HTTP_CE_TYPE"        => encoded_weird_type,
      "HTTP_CE_SPECVERSION" => spec_version,
      "CONTENT_TYPE"        => my_content_type_string,
      "HTTP_CE_DATASCHEMA"  => my_schema_string,
      "HTTP_CE_SUBJECT"     => my_subject,
      "HTTP_CE_TIME"        => my_time_string,
    }
  end
  let :my_simple_event do
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
  let :my_json_event do
    CloudEvents::Event::V1.new(data_encoded: my_json_escaped_simple_data,
                               data: my_simple_data,
                               datacontenttype: my_json_content_type_string,
                               dataschema: my_schema_string,
                               id: my_id,
                               source: my_source_string,
                               specversion: spec_version,
                               subject: my_subject,
                               time: my_time_string,
                               type: my_type)
  end
  let :my_minimal_event do
    CloudEvents::Event::V1.new(data_encoded: "",
                               data: "",
                               id: my_id,
                               source: my_source_string,
                               specversion: spec_version,
                               type: my_type)
  end
  let :my_extensions_event do
    CloudEvents::Event::V1.new(data_encoded: my_simple_data,
                               data: my_simple_data,
                               datacontenttype: my_content_type_string,
                               dataschema: my_schema_string,
                               id: my_id,
                               source: my_source_string,
                               specversion: spec_version,
                               subject: my_subject,
                               time: my_time_string,
                               tracecontext: my_trace_context,
                               type: my_type)
  end
  let :my_nonascii_event do
    CloudEvents::Event::V1.new(data_encoded: my_simple_data,
                               data: my_simple_data,
                               datacontenttype: my_content_type_string,
                               dataschema: my_schema_string,
                               id: my_id,
                               source: my_source_string,
                               specversion: spec_version,
                               subject: my_subject,
                               time: my_time_string,
                               type: weird_type)
  end

  def assert_request_matches(env, headers, body)
    env = env.dup
    assert_equal(env.delete("rack.input").read, body)
    headers_env = {}
    headers.each do |k, v|
      k = k.tr("-", "_").upcase
      k = "HTTP_#{k}" unless k == "CONTENT_TYPE"
      headers_env[k] = v
    end
    assert_equal(env, headers_env)
  end

  describe "percent_encode" do
    it "percent-encodes an ascii string" do
      str = http_binding.percent_encode(my_simple_data)
      assert_equal my_simple_data, str
    end

    it "percent-encodes a string with special characters" do
      str = http_binding.percent_encode(weird_type)
      assert_equal encoded_weird_type, str
    end
  end

  describe "percent_decode" do
    it "percent-decodes an ascii string" do
      str = http_binding.percent_decode(my_simple_data)
      assert_equal my_simple_data, str
    end

    it "percent-decodes a string with special characters" do
      str = http_binding.percent_decode(encoded_weird_type)
      assert_equal weird_type, str
    end

    it "percent-decodes a string with quoted tokens" do
      str = http_binding.percent_decode(encoded_quoted_type)
      assert_equal quoted_type, str
    end
  end

  describe "decode_event" do
    it "decodes a json-structured rack env with text content type" do
      env = {
        "rack.input"   => StringIO.new(my_json_struct_encoded),
        "CONTENT_TYPE" => "application/cloudevents+json",
      }
      event = http_binding.decode_event(env)
      assert_equal my_simple_event, event
    end

    it "decodes a json-structured rack env with json content type" do
      env = {
        "rack.input"   => StringIO.new(my_json_data_struct_encoded),
        "CONTENT_TYPE" => "application/cloudevents+json",
      }
      event = http_binding.decode_event(env)
      assert_equal my_json_event, event
    end

    it "decodes a json-batch rack env with text content type" do
      env = {
        "rack.input"   => StringIO.new(my_json_batch_encoded),
        "CONTENT_TYPE" => "application/cloudevents-batch+json",
      }
      events = http_binding.decode_event(env)
      assert_equal [my_simple_event], events
    end

    it "decodes a binary mode rack env with text content type" do
      event = http_binding.decode_event(my_simple_binary_mode)
      assert_equal my_simple_event, event
    end

    it "decodes a binary mode rack env with json content type" do
      event = http_binding.decode_event(my_json_binary_mode)
      assert_equal my_json_event, event
    end

    it "decodes a binary mode rack env using an InputWrapper" do
      my_simple_binary_mode["rack.input"] = StringIO.new(my_simple_data)
      event = http_binding.decode_event(my_simple_binary_mode)
      assert_equal my_simple_event, event
    end

    it "decodes a binary mode rack env omitting optional headers" do
      event = http_binding.decode_event(my_minimal_binary_mode)
      assert_equal my_minimal_event, event
    end

    it "decodes a binary mode rack env with extension headers" do
      event = http_binding.decode_event(my_extensions_binary_mode)
      assert_equal my_extensions_event, event
    end

    it "decodes a binary mode rack env with non-ascii characters in a header" do
      event = http_binding.decode_event(my_nonascii_binary_mode)
      assert_equal my_nonascii_event, event
    end

    it "decodes a structured event using opaque" do
      env = {
        "rack.input"   => StringIO.new(my_json_struct_encoded),
        "CONTENT_TYPE" => "application/cloudevents+json",
      }
      event = minimal_http_binding.decode_event(env, allow_opaque: true)
      assert_kind_of CloudEvents::Event::Opaque, event
      refute event.batch?
      assert_equal my_json_struct_encoded, event.content
      assert_equal CloudEvents::ContentType.new("application/cloudevents+json"), event.content_type
    end

    it "decodes a structured batch using opaque" do
      env = {
        "rack.input"   => StringIO.new(my_json_batch_encoded),
        "CONTENT_TYPE" => "application/cloudevents-batch+json",
      }
      event = minimal_http_binding.decode_event(env, allow_opaque: true)
      assert_kind_of CloudEvents::Event::Opaque, event
      assert event.batch?
      assert_equal my_json_batch_encoded, event.content
      assert_equal CloudEvents::ContentType.new("application/cloudevents-batch+json"), event.content_type
    end

    it "raises UnsupportedFormatError when a format is not recognized" do
      env = {
        "rack.input"   => StringIO.new(my_json_struct_encoded),
        "CONTENT_TYPE" => "application/cloudevents+hello",
      }
      assert_raises CloudEvents::UnsupportedFormatError do
        http_binding.decode_event(env)
      end
    end

    it "raises FormatSyntaxError when decoding malformed JSON event" do
      env = {
        "rack.input"   => StringIO.new("!!!"),
        "CONTENT_TYPE" => "application/cloudevents+json",
      }
      error = assert_raises(CloudEvents::FormatSyntaxError) do
        http_binding.decode_event(env)
      end
      assert_kind_of JSON::ParserError, error.cause
    end

    it "raises FormatSyntaxError when decoding malformed JSON batch" do
      env = {
        "rack.input"   => StringIO.new("!!!"),
        "CONTENT_TYPE" => "application/cloudevents-batch+json",
      }
      error = assert_raises(CloudEvents::FormatSyntaxError) do
        http_binding.decode_event(env)
      end
      assert_kind_of JSON::ParserError, error.cause
    end

    it "raises SpecVersionError when decoding a binary event with a bad specversion" do
      env = {
        "HTTP_CE_ID"          => my_id,
        "HTTP_CE_SOURCE"      => my_source_string,
        "HTTP_CE_TYPE"        => my_type,
        "HTTP_CE_SPECVERSION" => "0.1",
      }
      assert_raises CloudEvents::SpecVersionError do
        http_binding.decode_event(env)
      end
    end

    it "raises NotCloudEventError when a content-type is not recognized" do
      env = {
        "rack.input"   => StringIO.new(my_json_struct_encoded),
        "CONTENT_TYPE" => "application/json",
      }
      assert_raises CloudEvents::NotCloudEventError do
        http_binding.decode_event(env)
      end
    end

    it "raises NotCloudEventError when the method is GET" do
      env = {
        "REQUEST_METHOD" => "GET",
        "rack.input"   => StringIO.new(my_json_struct_encoded),
        "CONTENT_TYPE" => "application/cloudevents+json",
      }
      assert_raises CloudEvents::NotCloudEventError do
        http_binding.decode_event(env)
      end
    end

    it "raises NotCloudEventError when the method is HEAD" do
      env = {
        "REQUEST_METHOD" => "HEAD",
        "rack.input"   => StringIO.new(my_json_struct_encoded),
        "CONTENT_TYPE" => "application/cloudevents+json",
      }
      assert_raises CloudEvents::NotCloudEventError do
        http_binding.decode_event(env)
      end
    end
  end

  describe "encode_event" do
    it "encodes an event with text contenxt type to json-structured mode" do
      headers, body = http_binding.encode_event(my_simple_event, structured_format: true, sort: true)
      assert_equal({ "Content-Type" => "application/cloudevents+json; charset=utf-8" }, headers)
      assert_equal my_json_struct_encoded, body
    end

    it "encodes an event with json contenxt type to json-structured mode" do
      headers, body = http_binding.encode_event(my_json_event, structured_format: true, sort: true)
      assert_equal({ "Content-Type" => "application/cloudevents+json; charset=utf-8" }, headers)
      assert_equal my_json_data_struct_encoded, body
    end

    it "encodes a batch of events to json-structured mode" do
      headers, body = http_binding.encode_event([my_simple_event], structured_format: true, sort: true)
      assert_equal({ "Content-Type" => "application/cloudevents-batch+json; charset=utf-8" }, headers)
      assert_equal my_json_batch_encoded, body
    end

    it "encodes an event with text content type to binary mode" do
      headers, body = http_binding.encode_event(my_simple_event)
      assert_request_matches my_simple_binary_mode, headers, body
    end

    it "encodes an event with json content type to binary mode" do
      headers, body = http_binding.encode_event(my_json_event)
      assert_request_matches my_json_binary_mode, headers, body
    end

    it "encodes an event omitting optional attributes to binary mode" do
      headers, body = http_binding.encode_event(my_minimal_event)
      assert_request_matches my_minimal_binary_mode, headers, body
    end

    it "encodes an event with extension attributes to binary mode" do
      headers, body = http_binding.encode_event(my_extensions_event)
      assert_request_matches my_extensions_binary_mode, headers, body
    end

    it "encodes an event with non-ascii attribute characters to binary mode" do
      headers, body = http_binding.encode_event(my_nonascii_event)
      assert_request_matches my_nonascii_binary_mode, headers, body
    end

    it "decodes a structured event using opaque" do
      event = CloudEvents::Event::Opaque.new(my_json_struct_encoded,
                                             CloudEvents::ContentType.new("application/cloudevents+json"))
      headers, body = minimal_http_binding.encode_event(event)
      assert_equal({ "Content-Type" => "application/cloudevents+json" }, headers)
      assert_equal my_json_struct_encoded, body
    end

    it "decodes a structured batch using opaque" do
      event = CloudEvents::Event::Opaque.new(my_json_batch_encoded,
                                             CloudEvents::ContentType.new("application/cloudevents-batch+json"))
      headers, body = minimal_http_binding.encode_event(event)
      assert_equal({ "Content-Type" => "application/cloudevents-batch+json" }, headers)
      assert_equal my_json_batch_encoded, body
    end
  end

  describe "deprecated methods" do
    it "decodes a binary mode rack env with text content type" do
      event = http_binding.decode_rack_env(my_simple_binary_mode)
      expected_attributes = my_simple_event.to_h
      expected_attributes.delete("data_encoded")
      assert_equal expected_attributes, event.to_h
    end

    it "encodes an event with text contenxt type to binary mode" do
      headers, body = http_binding.encode_binary_content(my_simple_event, sort: true)
      assert_request_matches my_simple_binary_mode, headers, body
    end

    it "returns nil from the legacy decode method when a content-type is not recognized" do
      env = {
        "rack.input"   => StringIO.new(my_json_struct_encoded),
        "CONTENT_TYPE" => "application/json",
      }
      assert_nil http_binding.decode_rack_env(env)
    end
  end

  describe "probable_event?" do
    it "detects a probable binary event" do
      env = {
        "HTTP_CE_SPECVERSION" => "1.0",
      }
      assert http_binding.probable_event?(env)
    end

    it "detects a probable structured event" do
      env = {
        "CONTENT_TYPE" => "application/cloudevents+myformat",
      }
      assert http_binding.probable_event?(env)
    end

    it "detects a probable batch event" do
      env = {
        "CONTENT_TYPE" => "application/cloudevents-batch+myformat",
      }
      assert http_binding.probable_event?(env)
    end

    it "detects a content type that is unlikely an event" do
      env = {
        "CONTENT_TYPE" => "application/json",
      }
      refute http_binding.probable_event?(env)
    end

    it "detects that an HTTP GET unlikely an event" do
      env = {
        "REQUEST_METHOD" => "GET",
        "HTTP_CE_SPECVERSION" => "1.0",
      }
      refute http_binding.probable_event?(env)
    end

    it "detects that an HTTP HEAD unlikely an event" do
      env = {
        "REQUEST_METHOD" => "HEAD",
        "HTTP_CE_SPECVERSION" => "1.0",
      }
      refute http_binding.probable_event?(env)
    end
  end
end
