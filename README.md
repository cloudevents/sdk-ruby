# Ruby SDK for [CloudEvents](https://github.com/cloudevents/spec)

## Status

This SDK is still considered a work in progress, therefore things might (and
will) break with every update.

This SDK current supports the following versions of CloudEvents:
- v0.1

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
       -H 'CE-CloudEventsVersion: 1' \
       -H 'CE-EventType: com.example.someevent' \
       -H 'CE-Source: /mycontext' \
       -H 'CE-EventID: 1234-1234-1234' \
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

## Community

- There are bi-weekly calls immediately following the [Serverless/CloudEvents
  call](https://github.com/cloudevents/spec#meeting-time) at
  9am PT (US Pacific). Which means they will typically start at 10am PT, but
  if the other call ends early then the SDK call will start early as well.
  See the [CloudEvents meeting minutes](https://docs.google.com/document/d/1OVF68rpuPK5shIHILK9JOqlZBbfe91RNzQ7u_P7YCDE/edit#)
  to determine which week will have the call.
- Slack: #cloudeventssdk channel under
  [CNCF's Slack workspace](https://slack.cncf.io/).
- Contact for additional information: TBD (`@...` on slack).

