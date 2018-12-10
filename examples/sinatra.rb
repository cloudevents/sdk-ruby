$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "sinatra"
require "cloudevents"

marshaller = Cloudevents::V01::HTTPMarshaller.default

post "/" do
  event = marshaller.from_request(request)
  logger.info("Received cloudevent: #{event.inspect}")
end
