# frozen_string_literal: true

require_relative "helper"

require "date"
require "json"
require "stringio"
require "uri"
require "rack/lint"

describe CloudEvents::HttpBinding do
  let(:http_binding) { CloudEvents::HttpBinding.default }
  let(:minimal_http_binding) { CloudEvents::HttpBinding.new }
  let(:my_id) { "my_id" }
  let(:my_source_string) { "/my_source" }
  let(:my_source) { URI.parse my_source_string }
  let(:my_type) { "my_type" }
  let(:weird_type) { "¡Hola!\n\"100%\" 😀 " }
  let(:encoded_weird_type) { "%C2%A1Hola!%0A%22100%25%22%20%F0%9F%98%80%20" }
  let(:quoted_type) { "Hello Ruby world this\"is\\a1string okay" }
  let(:encoded_quoted_type) { "Hello%20\"Ruby%20world\"%20\"this\\\"is\\\\a\\1string\"%20okay" }
  let(:spec_version) { "1.0" }
  let(:my_simple_data) { "12345" }
  let(:my_json_escaped_simple_data) { '"12345"' }
  let(:my_content_type_string) { "text/plain; charset=us-ascii" }
  let(:my_content_type) { CloudEvents::ContentType.new my_content_type_string }
  let(:my_json_content_type_string) { "application/json; charset=us-ascii" }
  let(:my_json_content_type) { CloudEvents::ContentType.new my_json_content_type_string }
  let(:my_schema_string) { "/my_schema" }
  let(:my_schema) { URI.parse my_schema_string }
  let(:my_subject) { "my_subject" }
  let(:my_time_string) { "2020-01-12T20:52:05-08:00" }
  let(:my_time) { DateTime.rfc3339 my_time_string }
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
      "type"            => my_type
    }
  end
  let(:my_json_struct_encoded) { JSON.dump my_json_struct }
  let(:my_json_batch_encoded) { JSON.dump [my_json_struct] }
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
      "type"            => my_type
    }
  end
  let(:my_json_data_struct_encoded) { JSON.dump my_json_data_struct }

  it "percent-encodes an ascii string" do
    str = http_binding.percent_encode my_simple_data
    assert_equal my_simple_data, str
  end

  it "percent-decodes an ascii string" do
    str = http_binding.percent_decode my_simple_data
    assert_equal my_simple_data, str
  end

  it "percent-encodes a string with special characters" do
    str = http_binding.percent_encode weird_type
    assert_equal encoded_weird_type, str
  end

  it "percent-decodes a string with special characters" do
    str = http_binding.percent_decode encoded_weird_type
    assert_equal weird_type, str
  end

  it "percent-decodes a string with quoted tokens" do
    str = http_binding.percent_decode encoded_quoted_type
    assert_equal quoted_type, str
  end

  it "decodes a structured rack env and re-encodes as batch" do
    env = {
      "rack.input"   => StringIO.new(my_json_struct_encoded),
      "CONTENT_TYPE" => "application/cloudevents+json"
    }
    event = http_binding.decode_event env
    assert_equal my_id, event.id
    assert_equal my_source, event.source
    assert_equal my_type, event.type
    assert_equal spec_version, event.spec_version
    assert_equal my_simple_data, event.data
    assert_equal my_content_type, event.data_content_type
    assert_equal my_schema, event.data_schema
    assert_equal my_subject, event.subject
    assert_equal my_time, event.time
    headers, body = http_binding.encode_event [event], structured_format: true, sort: true
    assert_equal({ "Content-Type" => "application/cloudevents-batch+json; charset=utf-8" }, headers)
    assert_equal my_json_batch_encoded, body
  end

  it "decodes a batch rack env and re-encodes as binary" do
    env = {
      "rack.input"   => StringIO.new(my_json_batch_encoded),
      "CONTENT_TYPE" => "application/cloudevents-batch+json"
    }
    events = http_binding.decode_event env
    assert_equal 1, events.size
    event = events.first
    assert_equal my_id, event.id
    assert_equal my_source, event.source
    assert_equal my_type, event.type
    assert_equal spec_version, event.spec_version
    assert_equal my_simple_data, event.data
    assert_equal my_content_type, event.data_content_type
    assert_equal my_schema, event.data_schema
    assert_equal my_subject, event.subject
    assert_equal my_time, event.time
    headers, body = http_binding.encode_event event
    expected_headers = {
      "CE-id"          => my_id,
      "CE-source"      => my_source_string,
      "CE-type"        => my_type,
      "CE-specversion" => spec_version,
      "Content-Type"   => my_content_type_string,
      "CE-dataschema"  => my_schema_string,
      "CE-subject"     => my_subject,
      "CE-time"        => my_time_string
    }
    assert_equal expected_headers, headers
    assert_equal my_simple_data, body
  end

  it "decodes a binary rack env and re-encodes as structured" do
    env = {
      "rack.input"          => StringIO.new(my_simple_data),
      "HTTP_CE_ID"          => my_id,
      "HTTP_CE_SOURCE"      => my_source_string,
      "HTTP_CE_TYPE"        => my_type,
      "HTTP_CE_SPECVERSION" => spec_version,
      "CONTENT_TYPE"        => my_content_type_string,
      "HTTP_CE_DATASCHEMA"  => my_schema_string,
      "HTTP_CE_SUBJECT"     => my_subject,
      "HTTP_CE_TIME"        => my_time_string
    }
    event = http_binding.decode_event env
    assert_equal my_id, event.id
    assert_equal my_source, event.source
    assert_equal my_type, event.type
    assert_equal spec_version, event.spec_version
    assert_equal my_simple_data, event.data
    assert_equal my_content_type, event.data_content_type
    assert_equal my_schema, event.data_schema
    assert_equal my_subject, event.subject
    assert_equal my_time, event.time
    headers, body = http_binding.encode_event event, structured_format: true, sort: true
    assert_equal({ "Content-Type" => "application/cloudevents+json; charset=utf-8" }, headers)
    assert_equal my_json_struct_encoded, body
  end

  it "decodes a structured JSON rack env and re-encodes as binary" do
    env = {
      "rack.input"   => StringIO.new(my_json_data_struct_encoded),
      "CONTENT_TYPE" => "application/cloudevents+json"
    }
    event = http_binding.decode_event env
    assert_equal my_id, event.id
    assert_equal my_source, event.source
    assert_equal my_type, event.type
    assert_equal spec_version, event.spec_version
    assert_equal my_simple_data, event.data
    assert_equal my_json_content_type, event.data_content_type
    assert_equal my_schema, event.data_schema
    assert_equal my_subject, event.subject
    assert_equal my_time, event.time
    headers, body = http_binding.encode_event event
    expected_headers = {
      "CE-id"          => my_id,
      "CE-source"      => my_source_string,
      "CE-type"        => my_type,
      "CE-specversion" => spec_version,
      "Content-Type"   => my_json_content_type_string,
      "CE-dataschema"  => my_schema_string,
      "CE-subject"     => my_subject,
      "CE-time"        => my_time_string
    }
    assert_equal expected_headers, headers
    assert_equal my_json_escaped_simple_data, body
  end

  it "decodes a binary JSON rack env and re-encodes as structured" do
    env = {
      "rack.input"          => StringIO.new(my_json_escaped_simple_data),
      "HTTP_CE_ID"          => my_id,
      "HTTP_CE_SOURCE"      => my_source_string,
      "HTTP_CE_TYPE"        => my_type,
      "HTTP_CE_SPECVERSION" => spec_version,
      "CONTENT_TYPE"        => my_json_content_type_string,
      "HTTP_CE_DATASCHEMA"  => my_schema_string,
      "HTTP_CE_SUBJECT"     => my_subject,
      "HTTP_CE_TIME"        => my_time_string
    }
    event = http_binding.decode_event env
    assert_equal my_id, event.id
    assert_equal my_source, event.source
    assert_equal my_type, event.type
    assert_equal spec_version, event.spec_version
    assert_equal my_simple_data, event.data
    assert_equal my_json_content_type, event.data_content_type
    assert_equal my_schema, event.data_schema
    assert_equal my_subject, event.subject
    assert_equal my_time, event.time
    headers, body = http_binding.encode_event event, structured_format: true, sort: true
    assert_equal({ "Content-Type" => "application/cloudevents+json; charset=utf-8" }, headers)
    assert_equal my_json_data_struct_encoded, body
  end

  it "decodes and re-encodes a binary JSON rack env using deprecated methods" do
    env = {
      "rack.input"          => StringIO.new(my_simple_data),
      "HTTP_CE_ID"          => my_id,
      "HTTP_CE_SOURCE"      => my_source_string,
      "HTTP_CE_TYPE"        => my_type,
      "HTTP_CE_SPECVERSION" => spec_version,
      "CONTENT_TYPE"        => my_json_content_type_string,
      "HTTP_CE_DATASCHEMA"  => my_schema_string,
      "HTTP_CE_SUBJECT"     => my_subject,
      "HTTP_CE_TIME"        => my_time_string
    }
    event = http_binding.decode_rack_env env
    assert_equal my_id, event.id
    assert_equal my_source, event.source
    assert_equal my_type, event.type
    assert_equal spec_version, event.spec_version
    assert_equal my_simple_data, event.data
    assert_equal my_json_content_type, event.data_content_type
    assert_equal my_schema, event.data_schema
    assert_equal my_subject, event.subject
    assert_equal my_time, event.time
    headers, body = http_binding.encode_binary_content event, sort: true
    expected_headers = {
      "CE-id"          => my_id,
      "CE-source"      => my_source_string,
      "CE-type"        => my_type,
      "CE-specversion" => spec_version,
      "Content-Type"   => my_json_content_type_string,
      "CE-dataschema"  => my_schema_string,
      "CE-subject"     => my_subject,
      "CE-time"        => my_time_string
    }
    assert_equal expected_headers, headers
    assert_equal my_simple_data, body
  end

  it "decodes a binary rack env using an InputWrapper and re-encodes as structured" do
    env = {
      "rack.input"          => Rack::Lint::InputWrapper.new(StringIO.new(my_simple_data)),
      "HTTP_CE_ID"          => my_id,
      "HTTP_CE_SOURCE"      => my_source_string,
      "HTTP_CE_TYPE"        => my_type,
      "HTTP_CE_SPECVERSION" => spec_version,
      "CONTENT_TYPE"        => my_content_type_string,
      "HTTP_CE_DATASCHEMA"  => my_schema_string,
      "HTTP_CE_SUBJECT"     => my_subject,
      "HTTP_CE_TIME"        => my_time_string
    }
    event = http_binding.decode_event env
    assert_equal my_id, event.id
    assert_equal my_source, event.source
    assert_equal my_type, event.type
    assert_equal spec_version, event.spec_version
    assert_equal my_simple_data, event.data
    assert_equal my_content_type, event.data_content_type
    assert_equal my_schema, event.data_schema
    assert_equal my_subject, event.subject
    assert_equal my_time, event.time
    headers, body = http_binding.encode_event event, structured_format: true, sort: true
    assert_equal({ "Content-Type" => "application/cloudevents+json; charset=utf-8" }, headers)
    assert_equal my_json_struct_encoded, body
  end

  it "decodes and re-encodes binary, honoring optional headers" do
    env = {
      "HTTP_CE_ID"          => my_id,
      "HTTP_CE_SOURCE"      => my_source_string,
      "HTTP_CE_TYPE"        => my_type,
      "HTTP_CE_SPECVERSION" => spec_version
    }
    event = http_binding.decode_event env
    assert_equal my_id, event.id
    assert_equal my_source, event.source
    assert_equal my_type, event.type
    assert_equal spec_version, event.spec_version
    assert_nil event.data
    assert_nil event.data_content_type
    assert_nil event.data_schema
    assert_nil event.subject
    assert_nil event.time
    headers, body = http_binding.encode_event event
    expected_headers = {
      "CE-id"          => my_id,
      "CE-source"      => my_source_string,
      "CE-type"        => my_type,
      "CE-specversion" => spec_version,
      "Content-Type"   => "text/plain; charset=us-ascii"
    }
    assert_equal expected_headers, headers
    assert_equal "", body
  end

  it "decodes and re-encodes binary, passing through extension headers" do
    env = {
      "rack.input"           => StringIO.new(my_simple_data),
      "CONTENT_TYPE"         => my_content_type_string,
      "HTTP_CE_ID"           => my_id,
      "HTTP_CE_SOURCE"       => my_source_string,
      "HTTP_CE_TYPE"         => my_type,
      "HTTP_CE_SPECVERSION"  => spec_version,
      "HTTP_CE_TRACECONTEXT" => my_trace_context
    }
    event = http_binding.decode_event env
    assert_equal my_trace_context, event["tracecontext"]
    headers, body = http_binding.encode_event event
    expected_headers = {
      "CE-id"           => my_id,
      "CE-source"       => my_source_string,
      "CE-type"         => my_type,
      "CE-specversion"  => spec_version,
      "Content-Type"    => my_content_type_string,
      "CE-tracecontext" => my_trace_context
    }
    assert_equal expected_headers, headers
    assert_equal my_simple_data, body
  end

  it "encodes and decodes binary, with non-ascii header characters" do
    event = CloudEvents::Event.create spec_version:      spec_version,
                                      id:                my_id,
                                      source:            my_source,
                                      type:              weird_type,
                                      data:              my_simple_data,
                                      data_content_type: my_content_type_string
    headers, body = http_binding.encode_event event
    expected_headers = {
      "CE-id"          => my_id,
      "CE-source"      => my_source_string,
      "CE-type"        => encoded_weird_type,
      "CE-specversion" => spec_version,
      "Content-Type"   => my_content_type_string
    }
    assert_equal expected_headers, headers
    assert_equal my_simple_data, body

    env = {
      "rack.input"          => StringIO.new(body),
      "CONTENT_TYPE"        => my_content_type_string,
      "HTTP_CE_ID"          => my_id,
      "HTTP_CE_SOURCE"      => my_source_string,
      "HTTP_CE_TYPE"        => encoded_weird_type,
      "HTTP_CE_SPECVERSION" => spec_version
    }
    reconstituted_event = http_binding.decode_event env
    assert_equal event, reconstituted_event
  end

  it "raises UnsupportedFormatError when a format is not recognized" do
    env = {
      "rack.input"   => StringIO.new(my_json_struct_encoded),
      "CONTENT_TYPE" => "application/cloudevents+hello"
    }
    assert_raises CloudEvents::UnsupportedFormatError do
      http_binding.decode_event env
    end
  end

  it "raises FormatSyntaxError when decoding malformed JSON event" do
    env = {
      "rack.input"   => StringIO.new("!!!"),
      "CONTENT_TYPE" => "application/cloudevents+json"
    }
    error = assert_raises CloudEvents::FormatSyntaxError do
      http_binding.decode_event env
    end
    assert_kind_of JSON::ParserError, error.cause
  end

  it "raises FormatSyntaxError when decoding malformed JSON batch" do
    env = {
      "rack.input"   => StringIO.new("!!!"),
      "CONTENT_TYPE" => "application/cloudevents-batch+json"
    }
    error = assert_raises CloudEvents::FormatSyntaxError do
      http_binding.decode_event env
    end
    assert_kind_of JSON::ParserError, error.cause
  end

  it "raises SpecVersionError when decoding a binary event with a bad specversion" do
    env = {
      "HTTP_CE_ID"          => my_id,
      "HTTP_CE_SOURCE"      => my_source_string,
      "HTTP_CE_TYPE"        => my_type,
      "HTTP_CE_SPECVERSION" => "0.1"
    }
    assert_raises CloudEvents::SpecVersionError do
      http_binding.decode_event env
    end
  end

  it "raises NotCloudEventError when a content-type is not recognized" do
    env = {
      "rack.input"   => StringIO.new(my_json_struct_encoded),
      "CONTENT_TYPE" => "application/json"
    }
    assert_raises CloudEvents::NotCloudEventError do
      http_binding.decode_event env
    end
  end

  it "returns nil from the legacy decode method when a content-type is not recognized" do
    env = {
      "rack.input"   => StringIO.new(my_json_struct_encoded),
      "CONTENT_TYPE" => "application/json"
    }
    assert_nil http_binding.decode_rack_env env
  end

  it "decodes and re-encodes a structured event using opaque" do
    env = {
      "rack.input"   => StringIO.new(my_json_struct_encoded),
      "CONTENT_TYPE" => "application/cloudevents+json"
    }
    event = minimal_http_binding.decode_event env, allow_opaque: true
    assert_kind_of CloudEvents::Event::Opaque, event
    refute event.batch?
    headers, body = minimal_http_binding.encode_event event
    assert_equal({ "Content-Type" => "application/cloudevents+json" }, headers)
    assert_equal my_json_struct_encoded, body
  end

  it "decodes and re-encodes a batch of events using opaque" do
    env = {
      "rack.input"   => StringIO.new(my_json_batch_encoded),
      "CONTENT_TYPE" => "application/cloudevents-batch+json"
    }
    event = minimal_http_binding.decode_event env, allow_opaque: true
    assert_kind_of CloudEvents::Event::Opaque, event
    assert event.batch?
    headers, body = minimal_http_binding.encode_event event
    assert_equal({ "Content-Type" => "application/cloudevents-batch+json" }, headers)
    assert_equal my_json_batch_encoded, body
  end
end
