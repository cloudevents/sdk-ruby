# frozen_string_literal: true

require_relative "../helper"

require "date"
require "uri"

describe CloudEvents::Event::V1 do
  let(:my_id) { "my_id" }
  let(:my_source_string) { "/my_source" }
  let(:my_source) { URI.parse(my_source_string) }
  let(:my_source2_string) { "/my_source2" }
  let(:my_source2) { URI.parse(my_source2_string) }
  let(:my_type) { "my_type" }
  let(:my_type2) { "my_type2" }
  let(:spec_version) { "1.0" }
  let(:my_simple_data) { "12345" }
  let(:my_content_type_string) { "text/plain; charset=us-ascii" }
  let(:my_content_type) { CloudEvents::ContentType.new(my_content_type_string) }
  let(:my_object_data) { { "foo" => "bar" } }
  let(:my_object_data_encoded) { '{"foo":"bar"}' }
  let(:my_json_content_type_string) { "application/json; charset=us-ascii" }
  let(:my_json_content_type) { CloudEvents::ContentType.new(my_json_content_type_string) }
  let(:my_schema_string) { "/my_schema" }
  let(:my_schema) { URI.parse(my_schema_string) }
  let(:my_subject) { "my_subject" }
  let(:my_time_string) { "2020-01-12T20:52:05-08:00" }
  let(:my_date_time) { DateTime.rfc3339(my_time_string) }
  let(:my_time) { my_date_time.to_time }
  let(:my_trace_parent) { "12345678" }

  it "handles string inputs" do
    event = CloudEvents::Event::V1.new(id:                my_id,
                                       source:            my_source_string,
                                       type:              my_type,
                                       spec_version:      spec_version,
                                       data:              my_simple_data,
                                       data_encoded:      my_simple_data,
                                       data_content_type: my_content_type_string,
                                       data_schema:       my_schema_string,
                                       subject:           my_subject,
                                       time:              my_time_string)
    assert_equal my_id, event.id
    assert_equal my_source, event.source
    assert_equal my_type, event.type
    assert_equal spec_version, event.spec_version
    assert_equal my_simple_data, event.data
    assert_equal my_simple_data, event.data_encoded
    assert event.data_decoded?
    assert_equal my_content_type, event.data_content_type
    assert_equal my_schema, event.data_schema
    assert_equal my_subject, event.subject
    assert_equal my_date_time, event.time
    assert_equal my_id, event[:id]
    assert_equal my_source_string, event[:source]
    assert_equal my_type, event[:type]
    assert_equal spec_version, event[:specversion]
    assert_nil event[:spec_version]
    assert_equal my_simple_data, event[:data]
    assert_equal my_simple_data, event[:data_encoded]
    assert_equal my_content_type_string, event[:datacontenttype]
    assert_nil event[:data_content_type]
    assert_equal my_schema_string, event[:dataschema]
    assert_nil event[:data_schema]
    assert_equal my_subject, event[:subject]
    assert_equal my_time_string, event[:time]
    assert Ractor.shareable?(event) if defined? Ractor
  end

  it "handles object inputs" do
    event = CloudEvents::Event::V1.new(id:                my_id,
                                       source:            my_source,
                                       type:              my_type,
                                       spec_version:      spec_version,
                                       data:              my_object_data,
                                       data_encoded:      my_object_data_encoded,
                                       data_content_type: my_json_content_type,
                                       data_schema:       my_schema,
                                       subject:           my_subject,
                                       time:              my_date_time)
    assert_equal my_id, event.id
    assert_equal my_source, event.source
    assert_equal my_type, event.type
    assert_equal spec_version, event.spec_version
    assert_equal my_object_data, event.data
    assert_equal my_object_data_encoded, event.data_encoded
    assert event.data_decoded?
    assert_equal my_json_content_type, event.data_content_type
    assert_equal my_schema, event.data_schema
    assert_equal my_subject, event.subject
    assert_equal my_date_time, event.time
    assert_equal my_id, event[:id]
    assert_equal my_source_string, event[:source]
    assert_equal my_type, event[:type]
    assert_equal spec_version, event[:specversion]
    assert_nil event[:spec_version]
    assert_equal my_object_data, event[:data]
    assert_equal my_object_data_encoded, event[:data_encoded]
    assert_equal my_json_content_type_string, event[:datacontenttype]
    assert_nil event[:data_content_type]
    assert_equal my_schema_string, event[:dataschema]
    assert_nil event[:data_schema]
    assert_equal my_subject, event[:subject]
    assert_equal my_time_string, event[:time]
    assert Ractor.shareable?(event) if defined? Ractor
  end

  it "handles more object inputs" do
    event = CloudEvents::Event::V1.new(id:           my_id,
                                       source:       my_source,
                                       type:         my_type,
                                       spec_version: spec_version,
                                       data:         my_simple_data,
                                       time:         my_time)
    assert_equal my_id, event.id
    assert_equal my_source, event.source
    assert_equal my_type, event.type
    assert_equal spec_version, event.spec_version
    assert_equal my_simple_data, event.data
    assert_equal my_date_time, event.time
    assert Ractor.shareable?(event) if defined? Ractor
  end

  it "sets defaults when optional inputs are omitted" do
    event = CloudEvents::Event::V1.new(id:           my_id,
                                       source:       my_source,
                                       type:         my_type,
                                       spec_version: spec_version)
    assert_equal my_id, event.id
    assert_equal my_source, event.source
    assert_equal my_type, event.type
    assert_equal spec_version, event.spec_version
    assert_nil event.data
    assert_nil event.data_encoded
    refute event.data_decoded?
    assert_nil event.data_content_type
    assert_nil event.data_schema
    assert_nil event.subject
    assert_nil event.time
    assert_equal my_id, event[:id]
    assert_equal my_source_string, event[:source]
    assert_equal my_type, event[:type]
    assert_equal spec_version, event[:specversion]
    assert_nil event[:spec_version]
    assert_nil event[:data]
    assert_nil event[:data_encoded]
    assert_nil event[:datacontenttype]
    assert_nil event[:data_content_type]
    assert_nil event[:dataschema]
    assert_nil event[:data_schema]
    assert_nil event[:subject]
    assert_nil event[:time]
    assert_equal ["id", "source", "specversion", "type"], event.to_h.keys.sort
    assert Ractor.shareable?(event) if defined? Ractor
  end

  it "handles data set but not data_encoded" do
    event = CloudEvents::Event::V1.new(id:                my_id,
                                       source:            my_source_string,
                                       type:              my_type,
                                       spec_version:      spec_version,
                                       data:              my_simple_data,
                                       data_content_type: my_content_type_string,
                                       data_schema:       my_schema_string,
                                       subject:           my_subject,
                                       time:              my_time_string)
    assert_equal my_simple_data, event.data
    assert_nil event.data_encoded
    assert event.data_decoded?
    assert_equal my_simple_data, event[:data]
    assert_nil event[:data_encoded]
  end

  it "handles data_encoded set but not data" do
    event = CloudEvents::Event::V1.new(id:                my_id,
                                       source:            my_source_string,
                                       type:              my_type,
                                       spec_version:      spec_version,
                                       data_encoded:      my_simple_data,
                                       data_content_type: my_content_type_string,
                                       data_schema:       my_schema_string,
                                       subject:           my_subject,
                                       time:              my_time_string)
    assert_equal my_simple_data, event.data_encoded
    assert_equal my_simple_data, event.data
    refute event.data_decoded?
    assert_nil event[:data]
    assert_equal my_simple_data, event[:data_encoded]
  end

  it "creates a modified copy" do
    event = CloudEvents::Event::V1.new(id:                my_id,
                                       source:            my_source_string,
                                       type:              my_type,
                                       spec_version:      spec_version,
                                       data:              my_simple_data,
                                       data_content_type: my_content_type_string,
                                       data_schema:       my_schema_string,
                                       subject:           my_subject,
                                       time:              my_time_string)
    event2 = event.with(type: my_type2, source: my_source2)
    assert_equal my_id, event2.id
    assert_equal my_source2, event2.source
    assert_equal my_type2, event2.type
    assert_equal my_schema, event2.data_schema
    assert Ractor.shareable?(event2) if defined? Ractor
  end

  it "creates a modified copy changing the data" do
    event = CloudEvents::Event::V1.new(id:                my_id,
                                       source:            my_source_string,
                                       type:              my_type,
                                       spec_version:      spec_version,
                                       data_encoded:      my_simple_data,
                                       data_content_type: my_content_type_string,
                                       data_schema:       my_schema_string,
                                       subject:           my_subject,
                                       time:              my_time_string)
    assert_equal my_simple_data, event.data
    assert_equal my_simple_data, event.data_encoded
    refute event.data_decoded?
    event2 = event.with(data: my_simple_data)
    assert_nil event2.data_encoded
    assert_equal my_simple_data, event2.data
    assert event2.data_decoded?
    assert Ractor.shareable?(event2) if defined? Ractor
  end

  it "requires specversion" do
    error = assert_raises(CloudEvents::AttributeError) do
      CloudEvents::Event::V1.new(id:     my_id,
                                 source: my_source,
                                 type:   my_type)
    end
    assert_equal "The specversion field is required", error.message
  end

  it "errors when the wrong specversion is given" do
    error = assert_raises(CloudEvents::SpecVersionError) do
      CloudEvents::Event::V1.new(id:           my_id,
                                 source:       my_source,
                                 type:         my_type,
                                 spec_version: "0.3")
    end
    assert_equal "Unrecognized specversion: 0.3", error.message
  end

  it "requires id" do
    error = assert_raises(CloudEvents::AttributeError) do
      CloudEvents::Event::V1.new(source:       my_source,
                                 type:         my_type,
                                 spec_version: spec_version)
    end
    assert_equal "The id field is required", error.message
  end

  it "requires source" do
    error = assert_raises(CloudEvents::AttributeError) do
      CloudEvents::Event::V1.new(id:           my_id,
                                 type:         my_type,
                                 spec_version: spec_version)
    end
    assert_equal "The source field is required", error.message
  end

  it "requires type" do
    error = assert_raises(CloudEvents::AttributeError) do
      CloudEvents::Event::V1.new(id:           my_id,
                                 source:       my_source,
                                 spec_version: spec_version)
    end
    assert_equal "The type field is required", error.message
  end

  it "validates attribute name" do
    CloudEvents::Event::V1.new(id:           my_id,
                               source:       my_source,
                               type:         my_type,
                               spec_version: spec_version,
                               "1parent":    my_trace_parent)
    error = assert_raises(CloudEvents::AttributeError) do
      CloudEvents::Event::V1.new(id:           my_id,
                                 source:       my_source,
                                 type:         my_type,
                                 spec_version: spec_version,
                                 trace_parent: my_trace_parent)
    end
    assert_includes error.message, "Illegal key: \"trace_parent\""
  end

  it "handles extension attributes" do
    event = CloudEvents::Event::V1.new(id:           my_id,
                                       source:       my_source,
                                       type:         my_type,
                                       spec_version: spec_version,
                                       traceparent:  my_trace_parent)
    assert_equal my_trace_parent, event[:traceparent]
    assert_equal my_trace_parent, event.to_h["traceparent"]
  end

  it "handles nonstring extension attributes" do
    event = CloudEvents::Event::V1.new(id:           my_id,
                                       source:       my_source,
                                       type:         my_type,
                                       spec_version: spec_version,
                                       dataref:      my_source)
    assert_equal my_source_string, event[:dataref]
    assert_equal my_source_string, event.to_h["dataref"]
  end

  it "handles nil extension attributes" do
    event = CloudEvents::Event::V1.new(id:           my_id,
                                       source:       my_source,
                                       type:         my_type,
                                       spec_version: spec_version,
                                       traceparent:  nil)
    assert_nil event[:traceparent]
    refute_includes event.to_h, "traceparent"
  end

  it "returns a deep copy from to_h" do
    my_data = { "a" => [1, 2, 3, 4] }
    event = CloudEvents::Event::V1.new(id:           my_id,
                                       source:       my_source_string,
                                       type:         my_type,
                                       spec_version: spec_version,
                                       data:         my_data)
    assert Ractor.shareable?(event) if defined? Ractor

    data_from_getter = event.data
    assert_equal my_data, data_from_getter
    assert data_from_getter.frozen?
    assert data_from_getter["a"].frozen?

    data_from_hash = event.to_h["data"]
    assert_equal my_data, data_from_hash
    refute data_from_hash.frozen?
    refute data_from_hash["a"].frozen?
  end

  it "checks equality" do
    event1 = CloudEvents::Event::V1.new(id:           my_id,
                                        source:       my_source,
                                        type:         my_type,
                                        spec_version: spec_version)
    event2 = CloudEvents::Event::V1.new(id:           my_id,
                                        source:       my_source,
                                        type:         my_type,
                                        spec_version: spec_version)
    event3 = CloudEvents::Event::V1.new(id:           my_id,
                                        source:       my_source2,
                                        type:         my_type,
                                        spec_version: spec_version)
    assert_equal event1, event2
    refute_equal event1, event3
  end
end
