module Cloudevents
  module V01
    class JSONConverter
      SUPPORTED_MEDIA_TYPES = [
        "application/cloudevents+json",
      ]

      def read(event, request, &block)
        json = JSON.parse(request.body.read)
        event.cloud_events_version = json["cloudEventsVersion"]
        event.event_type = json["eventType"]
        event.source = json["source"]
        event.event_id = json["eventID"]
        event.content_type = request.content_type
        event
      end

      def can_read?(media_type)
        SUPPORTED_MEDIA_TYPES.include?(media_type)
      end
    end
  end
end
