# frozen_string_literal: true

require "sinatra"
require "cloud_events"

cloud_events_http = CloudEvents::HttpBinding.default

post("/") do
  event = cloud_events_http.decode_event(request.env)
  logger.info("Received CloudEvent: #{event.to_h}")
end
