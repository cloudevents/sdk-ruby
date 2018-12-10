# Ruby SDK for [CloudEvents](https://github.com/cloudevents/spec)

**NOTE: This SDK is still considered work in progress, things might (and will) break with every update.**

Package **cloudevents** provides primitives to work with CloudEvents specification: https://github.com/cloudevents/spec.
This gem currently supports reading version 0.1 cloudevents in binary and json format.

# Usage
Parsing upstream Event from HTTP Request with the helps of [`gem 'sinatra'`](https://github.com/sinatra/sinatra):

Create a file named `app.rb` and add the following code.
```ruby
require "sinatra"
require "cloudevents"

marshaller = Cloudevents::V01::HTTPMarshaller.default

post "/" do
  event = marshaller.from_request(request)
  logger.info("Received cloudevent: #{event.inspect}")
end

```

Start the web application server and send a cloudevent.
```sh
$ ruby app.rb
$ curl -H 'Content-Type: application/json' \
       -H 'CE-Cloud-Events-Version: 1' \
       -H 'CE-Event-Type: com.example.someevent' \
       -H 'CE-Source: /mycontext' \
       -H 'CE-Event-ID: 1234-1234-1234' \
       -X POST \
       -d 'Hello CloudEvents!' \
       'http://localhost:4567'
```

The console should output your freshly send cloudevent.
```
INFO -- : Received cloudevent: #<Cloudevents::V01::Event:0x00007fbbd581f108 @cloud_events_version="1", @event_type="com.example.someevent", @event_type_version=nil, @source="/mycontext", @event_id="1234-1234-1234", @event_time=nil, @schema_url=nil, @content_type="application/json", @data="Hello CloudEvents!">
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'cloudevents'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cloudevents

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cloudevents/ruby-sdk.
