module Cloudevents
  module V01
    class Event
      attr_accessor :cloud_events_version,
                    :event_type,
                    :event_type_version,
                    :source,
                    :event_id,
                    :event_time,
                    :schema_url,
                    :content_type,
                    :data
    end
  end
end
