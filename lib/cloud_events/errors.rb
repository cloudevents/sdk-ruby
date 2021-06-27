# frozen_string_literal: true

module CloudEvents
  ##
  # Base class for all CloudEvents errors.
  #
  class CloudEventsError < ::StandardError
  end

  ##
  # An error raised when a protocol binding was asked to decode a CloudEvent
  # from input data, but does not believe that the data was intended to be a
  # CloudEvent. For example, the HttpBinding might raise this exception if
  # given a request that has neither the requisite headers for binary content
  # mode, nor an appropriate content-type for structured content mode.
  #
  class NotCloudEventError < CloudEventsError
  end

  ##
  # An error raised when a protocol binding was asked to decode a CloudEvent
  # from input data, and the data appears to be a CloudEvent, but was encoded
  # in a format that is not supported. Some protocol bindings can be configured
  # to return a {CloudEvents::Event::Opaque} object instead of raising this
  # error.
  #
  class UnsupportedFormatError < CloudEventsError
  end

  ##
  # An error raised when a protocol binding was asked to decode a CloudEvent
  # from input data, and the data appears to be intended as a CloudEvent, but
  # has unrecoverable format or syntax errors. This error _may_ have a `cause`
  # such as a `JSON::ParserError` with additional information.
  #
  class FormatSyntaxError < CloudEventsError
  end

  ##
  # An error raised when a `specversion` is set to a value not recognized or
  # supported by the SDK.
  #
  class SpecVersionError < CloudEventsError
  end

  ##
  # An error raised when a malformed CloudEvents attribute is encountered,
  # often because a required attribute is missing, or a value does not match
  # the attribute's type specification.
  #
  class AttributeError < CloudEventsError
  end

  ##
  # Alias of UnsupportedFormatError, for backward compatibility.
  #
  # @deprecated Will be removed in version 1.0. Use {UnsupportedFormatError}.
  #
  HttpContentError = UnsupportedFormatError
end
