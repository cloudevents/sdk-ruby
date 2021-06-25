# frozen_string_literal: true

require "base64"
require "json"

module CloudEvents
  ##
  # This module documents the method signatures that may be implemented by
  # formatters.
  #
  # Note that a formatter need not implement all methods. For example, an event
  # formatter should implement `decode_event` and `encode_event`, and may also
  # implement `decode_batch` and `encode_batch`, but might not implement
  # `decode_data` or `encode_data`. Additionally, this module itself is present
  # primarily for documentation, and need not be directly included by
  # implementations.
  #
  module Format
    ##
    # Decode an event from the given serialized input.
    #
    # The arguments comprise an input string representing the encoded event
    # from a protocol source such as an HTTP request body, and a ContentType.
    # All additional arguments are optional, and may or may not be considered
    # by the formatter.
    #
    # The formatter must return either an event object, or `nil` to signal that
    # the formatter does not recognize the input and believes it should be
    # handled by a different formatter.
    # It can also raise an error to indicate that it believes it should handle
    # the input, but that the data is malformed.
    #
    # @param input [String] The input as a string.
    # @param content_type [CloudEvents::ContentType,nil] The input content
    #     type, or `nil` if none is available.
    # @return [CloudEvents::Event] if decoding succeeded.
    # @return [nil] if a different formatter should be used.
    #
    def decode_event input, content_type, **_other_kwargs
      nil
    end

    ##
    # Encode an event to a string.
    #
    # The input must be a CloudEvent object. All additional arguments are
    # optional, and may or may not be considered by the formatter.
    #
    # The formatter must return either a tuple comprising the serialized form
    # of the event and an associated ContentType, or `nil` to signal that the
    # formatter is incapable of handling the given event and believes it should
    # be handled by a different formatter.
    # It can also raise an error to indicate that it believes it should handle
    # the input, but that the input is malformed.
    #
    # Implementations should make sure the encoding of the returned string is
    # correct. In particular, if the format uses binary data, the returned
    # string should have the appropriate `ASCII_8BIT` encoding, and the
    # returned ContentType should specify the appropriate charset.
    #
    # @param event [CloudEvents::Event] The input event.
    # @return [Array(String,CloudEvents::ContentType)] if encoding succeeded.
    # @return [nil] if a different formatter should be used.
    #
    def encode_event event, **_other_kwargs
      nil
    end

    ##
    # Decode a batch of events from the given serialized input.
    #
    # The arguments comprise an input string representing the encoded batch of
    # events from a protocol source such as an HTTP request body, and a
    # ContentType. All additional arguments are optional, and may or may not be
    # considered by the formatter.
    #
    # The formatter must return either an array (possibly empty) of event
    # objects, or `nil` to signal that the formatter does not recognize the
    # input and believes it should be handled by a different formatter.
    # It can also raise an error to indicate that it believes it should handle
    # the input, but that the data is malformed.
    #
    # @param input [String] The input as a string.
    # @param content_type [CloudEvents::ContentType,nil] The input content
    #     type, or `nil` if none is available.
    # @return [Array<CloudEvents::Event>] if decoding succeeded.
    # @return [nil] if a different formatter should be used.
    #
    def decode_batch input, content_type, **_other_kwargs
      nil
    end

    ##
    # Encode a batch of events to a string.
    #
    # The input must be an array of CloudEvent objects (which could be empty).
    # All additional arguments are optional, and may or may not be considered
    # by the formatter.
    #
    # The formatter must return either a tuple comprising the serialized form
    # of the batch and an associated ContentType, or `nil` to signal that the
    # formatter is incapable of handling the given batch and believes it should
    # be handled by a different formatter.
    # It can also raise an error to indicate that it believes it should handle
    # the input, but that the input is malformed.
    #
    # Implementations should make sure the encoding of the returned string is
    # correct. In particular, if the format uses binary data, the returned
    # string should have the appropriate `ASCII_8BIT` encoding, and the
    # returned ContentType should specify the appropriate charset.
    #
    # @param events [Array<CloudEvents::Event>] An array of input events.
    # @return [Array(String,CloudEvents::ContentType)] if encoding succeeded.
    # @return [nil] if a different formatter should be used.
    #
    def encode_batch events, **_other_kwargs
      nil
    end

    ##
    # Decode an event data object from string format.
    #
    # The arguments comprise an input string representing the encoded data from
    # a protocol source such as an HTTP request body, and a ContentType. All
    # additional arguments are optional, and may or may not be considered by
    # the formatter.
    #
    # The formatter must return either a tuple comprising the event data object
    # and a final ContentType (which may be the same as the input ContentType),
    # or `nil` to signal that the formatter does not recognize the input and
    # believes it should be handled by a different formatter.
    # It can also raise an error to indicate that it believes it should handle
    # the input, but that the input is malformed.
    #
    # @param data [String] The input data string.
    # @param content_type [CloudEvents::ContentType,nil] The input content
    #     type, or `nil` if none is available.
    # @return [Array(Object,CloudEvents::ContentType)] if decoding succeeded.
    # @return [nil] if a different formatter should be used.
    #
    def decode_data data, content_type, **_other_kwargs
      nil
    end

    ##
    # Encode an event data object to string format.
    #
    # The arguments comprise an object representing the event data, and a
    # suggested ContentType. All additional arguments are optional, and may or
    # may not be considered by the formatter.
    #
    # The formatter must return either a tuple comprising the encoded data
    # string and a final ContentType (which may be the same as the input
    # ContentType), or `nil` to signal that the formatter is incapable of
    # handling the given data object and believes it should be handled by a
    # different formatter.
    # It can also raise an error to indicate that it believes it should handle
    # the input, but that the input is malformed.
    #
    # @param data [Object] A data object to encode.
    # @param content_type [CloudEvents::ContentType,nil] The input content
    #     type, or `nil` if none is available.
    # @return [Array(String,CloudEvents::ContentType)] if encoding succeeded.
    # @return [nil] if a different formatter should be used.
    #
    def encode_data data, content_type, **_other_kwargs
      nil
    end
  end
end
