module Cloudevents
  module V01
    class BinaryConverter
      SUPPORTED_MEDIA_TYPES = [
        "application/json",
        "application/xml",
        "application/octet-stream",
      ]

      def read(event, request, &block)
        event.cloud_events_version = request.fetch_header("HTTP_CE_CLOUD_EVENTS_VERSION")
        event.event_type = request.fetch_header("HTTP_CE_EVENT_TYPE")
        event.event_type_version = request.fetch_header("HTTP_CE_EVENT_TYPE_VERSION") { nil }
        event.source = request.fetch_header("HTTP_CE_SOURCE")
        event.event_id = request.fetch_header("HTTP_CE_EVENT_ID")
        event.event_time = request.fetch_header("HTTP_CE_EVENT_TIME") { nil }
        event.schema_url = request.fetch_header("HTTP_CE_SCHEMA_URL") { nil }
        event.content_type = request.content_type
        event.data = block ? block.call(request.body) : request.body.read
        event
      end

      def can_read?(media_type)
        SUPPORTED_MEDIA_TYPES.include?(media_type)
      end
    end
  end
end
