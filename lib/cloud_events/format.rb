# frozen_string_literal: true

require "base64"
require "json"

module CloudEvents
  ##
  # This module documents the method signatures that may be implemented by
  # formatters.
  #
  # A formatter is an object that implements "structured" event encoding and
  # decoding strategies for a particular format (such as JSON). In general,
  # this includes four operations:
  #
  # * Decoding an entire event or batch of events from a input source.
  #   This is implemented by the {Format#decode_event} method.
  # * Encoding an entire event or batch of events to an output sink.
  #   This is implemented by the {Format#encode_event} method.
  # * Decoding an event payload (i.e. the `data` attribute) Ruby object from a
  #   serialized representation.
  #   This is implemented by the {Format#decode_data} method.
  # * Encoding an event payload (i.e. the `data` attribute) Ruby object to a
  #   serialized representation.
  #   This is implemented by the {Format#encode_data} method.
  #
  # Each method takes a set of keyword arguments, and returns either a `Hash`
  # or `nil`. A Hash indicates that the formatter understands the request and
  # is returning its response. A return value of `nil` means the formatter does
  # not understand the request and is declining to perform the operation. In
  # such a case, it is possible that a different formatter should handle it.
  #
  # Both the keyword arguments recognized and the returned hash members may
  # vary from formatter to formatter; similarly, the keyword arguments provided
  # and the resturned hash members recognized may also vary for different
  # callers. This interface will define a set of common argument and result key
  # names, but both callers and formatters must gracefully handle the case of
  # missing or extra information. For example, if a formatter expects a certain
  # argument but does not receive it, it can assume the caller does not have
  # the required information, and it may respond by returning `nil` to decline
  # the request. Similarly, if a caller expects a response key but does not
  # receive it, it can assume the formatter does not provide it, and it may
  # respond by trying a different formatter.
  #
  # Additionally, any particular formatter need not implement all methods. For
  # example, an event formatter would generally implement {Format#decode_event}
  # and {Format#encode_event}, but might not implement {Format#decode_data} or
  # {Format#encode_data}.
  #
  # Finally, this module itself is present primarily for documentation, and
  # need not be directly included by formatter implementations.
  #
  module Format
    ##
    # Decode an event or batch from the given serialized input. This is
    # typically called by a protocol binding to deserialize event data from an
    # input stream.
    #
    # Common arguments include:
    #
    # * `:content` (String) Serialized content to decode. For example, it could
    #   be from an HTTP request body.
    # * `:content_type` ({CloudEvents::ContentType}) The content type. For
    #   example, it could be from the `Content-Type` header of an HTTP request.
    #
    # The formatter must first determine whether it is able to interpret the
    # given input. Typically, this is done by inspecting the `content_type`.
    # If the formatter determines that it is unable to interpret the input, it
    # should return `nil`. Otherwise, if the formatter determines it can decode
    # the input, it should return a `Hash`. Common hash keys include:
    #
    # * `:event` ({CloudEvents::Event}) A single event decoded from the input.
    # * `:event_batch` (Array of {CloudEvents::Event}) A batch of events
    #   decoded from the input.
    #
    # The formatter may also raise a {CloudEvents::CloudEventsError} subclass
    # if it understood the request but determines that the input source is
    # malformed.
    #
    # @param _kwargs [keywords] Arguments
    # @return [Hash] if accepting the request and returning a result
    # @return [nil] if declining the request.
    #
    def decode_event **_kwargs
      nil
    end

    ##
    # Encode an event or batch to a string. This is typically called by a
    # protocol binding to serialize event data to an output stream.
    #
    # Common arguments include:
    #
    # * `:event` ({CloudEvents::Event}) A single event to encode.
    # * `:event_batch` (Array of {CloudEvents::Event}) A batch of events to
    #   encode.
    #
    # The formatter must first determine whether it is able to interpret the
    # given input. Typically, most formatters should be able to handle any
    # event or event batch, but a specialized formatter that can handle only
    # certain kinds of events may return `nil` to decline unwanted inputs.
    # Otherwise, if the formatter determines it can encode the input, it should
    # return a `Hash`. common hash keys include:
    #
    # * `:content` (String) The serialized form of the event. This might, for
    #   example, be written to an HTTP request body. Care should be taken to
    #   set the string's encoding properly. In particular, to output binary
    #   data, the encoding should probably be set to `ASCII_8BIT`.
    # * `:content_type` ({CloudEvents::ContentType}) The content type for the
    #   output. This might, for example, be written to the `Content-Type`
    #   header of an HTTP request.
    #
    # The formatter may also raise a {CloudEvents::CloudEventsError} subclass
    # if it understood the request but determines that the input source is
    # malformed.
    #
    # @param _kwargs [keywords] Arguments
    # @return [Hash] if accepting the request and returning a result
    # @return [nil] if declining the request.
    #
    def encode_event **_kwargs
      nil
    end

    ##
    # Decode an event data object from string format. This is typically called
    # by a protocol binding to deserialize the payload (i.e. `data` attribute)
    # of an event as part of "binary content mode" decoding.
    #
    # Common arguments include:
    #
    # * `:spec_version` (String) The `specversion` of the event.
    # * `:content` (String) Serialized payload to decode. For example, it could
    #   be from an HTTP request body.
    # * `:content_type` ({CloudEvents::ContentType}) The content type. For
    #   example, it could be from the `Content-Type` header of an HTTP request.
    #
    # The formatter must first determine whether it is able to interpret the
    # given input. Typically, this is done by inspecting the `content_type`.
    # If the formatter determines that it is unable to interpret the input, it
    # should return `nil`. Otherwise, if the formatter determines it can decode
    # the input, it should return a `Hash`. Common hash keys include:
    #
    # * `:data` (Object) The payload object to be set as the `data` attribute
    #   in a {CloudEvents::Event} object.
    # * `:content_type` ({CloudEvents::ContentType}) The content type to be set
    #   as the `datacontenttype` attribute in a {CloudEvents::Event} object.
    #   In many cases, this may simply be copied from the `:content_type`
    #   argument, but a formatter could modify it to provide corrections or
    #   additional information.
    #
    # The formatter may also raise a {CloudEvents::CloudEventsError} subclass
    # if it understood the request but determines that the input source is
    # malformed.
    #
    # @param _kwargs [keywords] Arguments
    # @return [Hash] if accepting the request and returning a result
    # @return [nil] if declining the request.
    #
    def decode_data **_kwargs
      nil
    end

    ##
    # Encode an event data object to string format. This is typically called by
    # a protocol binding to serialize the payload (i.e. `data` attribute and
    # corresponding `datacontenttype` attribute) of an event as part of "binary
    # content mode" encoding.
    #
    # Common arguments include:
    #
    # * `:spec_version` (String) The `specversion` of the event.
    # * `:data` (Object) The payload object from an event's `data` attribute.
    # * `:content_type` ({CloudEvents::ContentType}) The content type from an
    #   event's `datacontenttype` attribute.
    #
    # The formatter must first determine whether it is able to interpret the
    # given input. Typically, this is done by inspecting the `content_type`.
    # If the formatter determines that it is unable to interpret the input, it
    # should return `nil`. Otherwise, if the formatter determines it can decode
    # the input, it should return a `Hash`. Common hash keys include:
    #
    # * `:content` (String) The serialized form of the data. This might, for
    #   example, be written to an HTTP request body. Care should be taken to
    #   set the string's encoding properly. In particular, to output binary
    #   data, the encoding should generally be set to `ASCII_8BIT`.
    # * `:content_type` ({CloudEvents::ContentType}) The content type for the
    #   output. This might, for example, be written to the `Content-Type`
    #   header of an HTTP request.
    #
    # The formatter may also raise a {CloudEvents::CloudEventsError} subclass
    # if it understood the request but determines that the input source is
    # malformed.
    #
    # @param _kwargs [keywords] Arguments
    # @return [Hash] if accepting the request and returning a result
    # @return [nil] if declining the request.
    #
    def encode_data **_kwargs
      nil
    end

    ##
    # A convenience formatter that checks multiple formats for one capable of
    # handling the given input.
    #
    class Multi
      ##
      # Create a multi format.
      #
      # @param formats [Array<Format>] An array of formats to check in order
      # @param result_checker [Proc] An optional block that determines whether
      #     a result provided by a format is acceptable. The block takes the
      #     format's result as an argument, and returns either the result to
      #     indicate acceptability, or `nil` to indicate not.
      #
      def initialize formats = [], &result_checker
        @formats = formats
        @result_checker = result_checker
      end

      ##
      # The formats to check, in order.
      #
      # @return [Array<Format>]
      #
      attr_reader :formats

      ##
      # Implements {Format#decode_event}
      #
      def decode_event **kwargs
        @formats.each do |elem|
          result = elem.decode_event(**kwargs)
          result = @result_checker.call result if @result_checker
          return result if result
        end
        nil
      end

      ##
      # Implements {Format#encode_event}
      #
      def encode_event **kwargs
        @formats.each do |elem|
          result = elem.encode_event(**kwargs)
          result = @result_checker.call result if @result_checker
          return result if result
        end
        nil
      end

      ##
      # Implements {Format#decode_data}
      #
      def decode_data **kwargs
        @formats.each do |elem|
          result = elem.decode_data(**kwargs)
          result = @result_checker.call result if @result_checker
          return result if result
        end
        nil
      end

      ##
      # Implements {Format#encode_data}
      #
      def encode_data **kwargs
        @formats.each do |elem|
          result = elem.encode_data(**kwargs)
          result = @result_checker.call result if @result_checker
          return result if result
        end
        nil
      end
    end
  end
end
