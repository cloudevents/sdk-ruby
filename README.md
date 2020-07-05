# Ruby SDK for [CloudEvents](https://github.com/cloudevents/spec)

## CloudEvents Ruby SDK

A [Ruby](https://ruby-lang.org) language implementation of the
[CloudEvents specification](https://github.com/cloudevents/spec).

Features:

 *  Ruby classes for representing CloudEvents, including support for standard
    and extension attributes.
 *  Support for serializing and deserializing from JSON Structure Format and
    JSON Batch Format.
 *  Support for sending and receiving CloudEvents via HTTP Bindings.
 *  Supports the [CloudEvent 0.3](https://github.com/cloudevents/spec/tree/v0.3)
    and [CloudEvents 1.0](https://github.com/cloudevents/spec/tree/v1.0)
    specifications.
 *  Extensible to additional formats and protocol bindings, and future
    specification versions.

## Quickstart

Install the `cloud_events` gem or add it to your bundle.

```sh
gem install cloud_events
```

### Receiving a CloudEvent in a Sinatra app

A simple [Sinatra](https://sinatrarb.com) app that receives CloudEvents:

```ruby
# examples/server/Gemfile
source "https://rubygems.org"
gem "cloud_events", "~> 0.1"
gem "sinatra", "~> 2.0"
```

```ruby
# examples/server/app.rb
require "sinatra"
require "cloud_events"

cloud_events_http = CloudEvents::HttpBinding.default

post "/" do
  event = cloud_events_http.decode_rack_env request.env
  logger.info "Received CloudEvent: #{event.to_h}"
end
```

### Sending a CloudEvent

A simple Ruby script that sends a CloudEvent:

```ruby
# examples/client/Gemfile
source "https://rubygems.org"
gem "cloud_events", "~> 0.1"
```

```ruby
# examples/client/send.rb
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
```

### Putting it together

Start the server on localhost:

```sh
cd server
bundle install
bundle exec ruby app.rb
```

This will run the server in the foreground and start logging to the console.

In a separate terminal shell, send it an event from the client:

```sh
cd client
bundle install
bundle exec ruby send.rb
```

The event should be logged in the server logs.

Hit `CTRL+C` to stop the server.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cloudevents/ruby-sdk.

### Development

After cloning the repo locally, install the bundle, and install the `toys` gem
if you do not already have it.

```sh
bundle install
gem install toys
```

A variety of Toys scripts are provided for running tests and builds. For
example:

```sh
# Run the unit tests
toys test

# Run CI locally, including unit tests, doc tests, and rubocop
toys ci

# Build and install the gem locally
toys install

# Clean temporary and build files
toys clean

# List all available scripts
toys

# Show online help for the "test" script
toys test --help
```

### Releasing

Releases can be performed only by users with write access to the repository.

To perform a release:

 1. Update `lib/cloud_events/version.rb` with the new release version.

 2. Add an entry to `CHANGELOG.md`. The changelog entry _must_ be headed by
    the version and release date, and _must_ be consistent with the format of
    previous entries.

 3. Ensure the above changes are pushed to the GitHub master branch at
    https://github.com/cloudevents/ruby-sdk.

 4. Execute

        toys release trigger $VERSION

    where `$VERSION` is the version number (e.g. `0.1.0`). This script will
    verify the version and changelog and will not proceed unless they are
    correctly formatted and the master branch is up to date. If the check
    succeeds, the script will create and push a release tag.

 5. A GitHub action will then perform the release within a few minutes. You can
    check the [GitHub Actions dashboard](https://github.com/dazuma/toys/actions)
    for status information.

## Community

 *  **Weekly meetings:** There are bi-weekly calls immediately following the
    [Serverless/CloudEvents call](https://github.com/cloudevents/spec#meeting-time)
    at 9am PT (US Pacific). Which means they will typically start at 10am PT,
    but if the other call ends early then the SDK call will start early as
    well. See the
    [CloudEvents meeting minutes](https://docs.google.com/document/d/1OVF68rpuPK5shIHILK9JOqlZBbfe91RNzQ7u_P7YCDE/edit)
    to determine which week will have the call.

 *  **Slack:** The `#cloudeventssdk` channel under
    [CNCF's Slack workspace](https://slack.cncf.io/).

 *  **Email:** https://lists.cncf.io/g/cncf-cloudevents-sdk

 *  For additional information, contact Daniel Azuma (`@dazuma` on Slack).

## Licensing

    Copyright 2020 Google LLC and the CloudEvents Ruby SDK Contributors

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this software except in compliance with the License.
    You may obtain a copy of the License at

        https://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
