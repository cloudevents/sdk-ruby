# frozen_string_literal: true

require "date"
require "uri"

require "cloud_events/event/opaque"
require "cloud_events/event/v0"
require "cloud_events/event/v1"

module CloudEvents
  ##
  # An Event object represents a complete CloudEvent, including both data and
  # context attributes. The following are true of all event objects:
  #
  #  *  Event classes are defined within this module. For example, events
  #     conforming to the CloudEvents 1.0 specification are of type
  #     {CloudEvents::Event::V1}.
  #  *  All event classes include this module itself, so you can use
  #     `is_a? CloudEvents::Event` to test whether an object is an event.
  #  *  All event objects are immutable. Data and attribute values can be
  #     retrieved but not modified. To "modify" an event, make a copy with
  #     the desired changes. Generally, event classes will provide a helper
  #     method for this purpose.
  #  *  All event objects have a `spec_version` method that returns the
  #     version of the CloudEvents spec implemented by that event. (Other
  #     methods may be different, depending on the spec version.)
  #
  # To create an event, you may either:
  #
  #  *  Construct an instance of the event class directly, for example by
  #     calling {CloudEvents::Event::V1.new} and passing a set of attributes.
  #  *  Call {CloudEvents::Event.create} and pass a spec version and a set of
  #     attributes. This will choose the appropriate event class based on the
  #     version.
  #  *  Decode an event from another representation. For example, use
  #     {CloudEvents::JsonFormat} to decode an event from JSON, or use
  #     {CloudEvents::HttpBinding} to decode an event from an HTTP request.
  #
  # See https://github.com/cloudevents/spec for more information about
  # CloudEvents. The documentation for the individual event classes
  # {CloudEvents::Event::V0} and {CloudEvents::Event::V1} also include links to
  # their respective specifications.
  #
  module Event
    class << self
      ##
      # Create a new cloud event object with the given version. Generally,
      # you must also pass additional keyword arguments providing the event's
      # data and attributes. For example, if you pass `1.0` as the
      # `spec_version`, the remaining keyword arguments will be passed
      # through to the {CloudEvents::Event::V1} constructor.
      #
      # Note that argument objects passed in may get deep-frozen if they are
      # used in the final event object. This is particularly important for the
      # `:data` field, for example if you pass a structured hash. If this is an
      # issue, make a deep copy of objects before passing them to this method.
      #
      # @param spec_version [String] The required `specversion` field.
      # @param kwargs [keywords] Additional parameters for the event.
      #
      def create spec_version:, **kwargs
        case spec_version
        when "0.3"
          V0.new spec_version: spec_version, **kwargs
        when /^1(\.|$)/
          V1.new spec_version: spec_version, **kwargs
        else
          raise SpecVersionError, "Unrecognized specversion: #{spec_version}"
        end
      end
      alias new create
    end
  end
end
