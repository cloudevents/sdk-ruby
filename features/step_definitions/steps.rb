# frozen_string_literal: true

require "webrick"
require "stringio"
require "rack"

Given "HTTP Protocol Binding is supported" do
  @http_binding = CloudEvents::HttpBinding.default
end

Given "an HTTP request" do |str|
  # WEBrick parsing wants the lines delimited by \r\n, but the input
  # content-length assumes \n within the body.
  parts = str.split("\n\n")
  parts[0].gsub!("\n", "\r\n")
  str = "#{parts[0]}\r\n\r\n#{parts[1]}"
  webrick_request = WEBrick::HTTPRequest.new(WEBrick::Config::HTTP)
  webrick_request.parse(StringIO.new(str))
  @rack_request = {}
  @rack_request[Rack::REQUEST_METHOD] = webrick_request.request_method
  @rack_request[Rack::SCRIPT_NAME] = webrick_request.script_name
  @rack_request[Rack::PATH_INFO] = webrick_request.path_info
  @rack_request[Rack::QUERY_STRING] = webrick_request.query_string
  @rack_request[Rack::SERVER_NAME] = webrick_request.server_name
  @rack_request[Rack::SERVER_PORT] = webrick_request.port
  @rack_request[Rack::RACK_VERSION] = Rack::VERSION
  @rack_request[Rack::RACK_URL_SCHEME] = webrick_request.ssl? ? "https" : "http"
  @rack_request[Rack::RACK_INPUT] = StringIO.new(webrick_request.body)
  @rack_request[Rack::RACK_ERRORS] = StringIO.new
  webrick_request.each do |key, value|
    key = key.upcase.tr("-", "_")
    key = "HTTP_#{key}" unless key == "CONTENT_TYPE"
    @rack_request[key] = value
  end
end

When "parsed as HTTP request" do
  @event = @http_binding.decode_event(@rack_request)
end

Then "the attributes are:" do |table|
  table.hashes.each do |hash|
    assert_equal hash["value"], @event[hash["key"]]
  end
end

Then "the data is equal to the following JSON:" do |str|
  json = JSON.parse(str)
  assert_equal json, @event.data
end

Given "Kafka Protocol Binding is supported" do
  pending "Kafka Protocol Binding is not yet implemented"
end

Given "a Kafka message with payload:" do |_str|
  pending
end

Given "Kafka headers:" do |_table|
  pending
end

When "parsed as Kafka message" do
  pending
end
