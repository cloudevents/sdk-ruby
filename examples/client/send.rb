require "cloud_events"
require "net/http"
require "uri"

data = { message: "Hello, CloudEvents!" }
event = CloudEvents::Event.create spec_version: "1.0",
                                  id:           "1234-1234-1234",
                                  source:       "/mycontext",
                                  type:         "com.example.someevent",
                                  data:         data

cloud_events_http = CloudEvents::HttpBinding.default
headers, body = cloud_events_http.encode_binary_content event
Net::HTTP.post URI("http://localhost:4567"), body, headers
