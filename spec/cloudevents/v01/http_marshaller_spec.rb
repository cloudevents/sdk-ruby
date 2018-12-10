require "spec_helper"

describe Cloudevents::V01::HTTPMarshaller do
  describe "#from_request" do
    context "request is nil" do
      it "raises" do
        principal = Cloudevents::V01::HTTPMarshaller.default

        -> { principal.from_request(nil) }.must_raise(ArgumentError)
      end
    end

    context "content type missing" do
      it "raises" do
        request = Rack::Request.new(Rack::MockRequest.env_for(
          "http://example.com/",
        ))
        principal = Cloudevents::V01::HTTPMarshaller.default

        -> { principal.from_request(request) }.must_raise(Cloudevents::ContentTypeNotSupportedError)
      end
    end

    context "invalid content type" do
      it "raises" do
        request = Rack::Request.new(Rack::MockRequest.env_for(
          "http://example.com/",
          "CONTENT_TYPE" => "application/",
        ))
        principal = Cloudevents::V01::HTTPMarshaller.default
      end
    end

    context "no converter" do
      it "raises" do
        request = Rack::Request.new(Rack::MockRequest.env_for(
          "http://example.com/",
          "CONTENT_TYPE" => "application/cloudevents+json",

        ))
        principal = Cloudevents::V01::HTTPMarshaller.new

        -> { principal.from_request(request) }.must_raise(Cloudevents::ContentTypeNotSupportedError)
      end
    end

    context "binary format" do
      context "with mandatory headers" do
        it "returns an event" do
          request = Rack::Request.new(Rack::MockRequest.env_for(
            "http://example.com/",
            "CONTENT_TYPE" => "application/json",
            "HTTP_CE_CLOUDEVENTSVERSION" => "1",
            "HTTP_CE_EVENTTYPE" => "com.example.someevent",
            "HTTP_CE_SOURCE" => "/mycontext",
            "HTTP_CE_EVENTID" => "1234-1234-1234",
            input: "Hello CloudEvents!",
          ))
          principal = Cloudevents::V01::HTTPMarshaller.default
          event = principal.from_request(request)

          event.content_type.must_equal("application/json")
          event.cloud_events_version.must_equal("1")
          event.event_type.must_equal("com.example.someevent")
          event.source.must_equal("/mycontext")
          event.event_id.must_equal("1234-1234-1234")
          event.event_type_version.must_be_nil
          event.event_time.must_be_nil
          event.schema_url.must_be_nil
          event.data.must_equal("Hello CloudEvents!")
        end
      end

      context "with all headers" do
        it "returns an event" do
          request = Rack::Request.new(Rack::MockRequest.env_for(
            "http://example.com/",
            "CONTENT_TYPE" => "application/json",
            "HTTP_CE_CLOUDEVENTSVERSION" => "1",
            "HTTP_CE_EVENTTYPE" => "com.example.someevent",
            "HTTP_CE_SOURCE" => "/mycontext",
            "HTTP_CE_EVENTID" => "1234-1234-1234",
            "HTTP_CE_EVENTTYPEVERSION" => "1.1",
            "HTTP_CE_EVENTTIME" => "2018-04-05T03:56:24Z",
            "HTTP_CE_SCHEMAURL" => "http://example.com/schema",
            input: "Hello CloudEvents!",
          ))
          principal = Cloudevents::V01::HTTPMarshaller.default
          event = principal.from_request(request)

          event.content_type.must_equal("application/json")
          event.cloud_events_version.must_equal("1")
          event.event_type.must_equal("com.example.someevent")
          event.source.must_equal("/mycontext")
          event.event_id.must_equal("1234-1234-1234")
          event.event_type_version.must_equal("1.1")
          event.event_time.must_equal("2018-04-05T03:56:24Z")
          event.schema_url.must_equal("http://example.com/schema")
          event.data.must_equal("Hello CloudEvents!")
        end
      end
    end

    context "json format" do
      context "with mandatory fields" do
        it "returns an event" do
          payload = <<-JSON
              {
                "cloudEventsVersion": "1",
                "eventType": "com.example.someevent",
                "source":  "/mycontext",
                "eventID": "1234-1234-1234"
              }
            JSON
          request = Rack::Request.new(Rack::MockRequest.env_for(
            "http://example.com/",
            "CONTENT_TYPE" => "application/cloudevents+json",
            input: payload,
          ))
          principal = Cloudevents::V01::HTTPMarshaller.default
          event = principal.from_request(request)

          event.content_type.must_equal("application/cloudevents+json")
          event.cloud_events_version.must_equal("1")
          event.event_type.must_equal("com.example.someevent")
          event.source.must_equal("/mycontext")
          event.event_id.must_equal("1234-1234-1234")
          event.event_type_version.must_be_nil
          event.event_time.must_be_nil
          event.schema_url.must_be_nil
          event.data.must_be_nil
        end
      end
    end
  end
end
