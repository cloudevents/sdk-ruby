# frozen_string_literal: true

require "base64"
require "json"

module CloudEvents
  ##
  # An data encoder/decoder for text content types. This handles any media type
  # of the form `text/*` or `application/octet-stream`, and passes strings
  # through as-is.
  #
  class TextFormat
    # @private
    UNSPECIFIED = ::Object.new.freeze

    ##
    # Trivially decode an event data string using text format.
    # See {CloudEvents::Format#decode_data} for a general description.
    #
    # Expects `:content` and `:content_type` arguments, and will decline the
    # request unless all three are provided.
    #
    # If decoding succeeded, returns a hash with the following keys:
    #
    # * `:data` (Object) The payload object to set as the `data` attribute.
    # * `:content_type` ({CloudEvents::ContentType}) The content type to be set
    #   as the `datacontenttype` attribute.
    #
    # @param content [String] Serialized content to decode.
    # @param content_type [CloudEvents::ContentType] The input content type.
    # @return [Hash] if accepting the request.
    # @return [nil] if declining the request.
    #
    def decode_data content: nil, content_type: nil, **_other_kwargs
      return nil unless content
      return nil unless text_content_type? content_type
      { data: content.to_s, content_type: content_type }
    end

    ##
    # Trivially an event data object using text format.
    # See {CloudEvents::Format#encode_data} for a general description.
    #
    # Expects `:data` and `:content_type` arguments, and will decline the
    # request unless all three are provided.
    # The `:data` object will be converted to a string if it is not already a
    # string.
    #
    # If decoding succeeded, returns a hash with the following keys:
    #
    # * `:content` (String) The serialized form of the data.
    # * `:content_type` ({CloudEvents::ContentType}) The content type for the
    #   output.
    #
    # @param data [Object] A data object to encode.
    # @param content_type [CloudEvents::ContentType] The input content type
    # @return [Hash] if accepting the request.
    # @return [nil] if declining the request.
    #
    def encode_data data: UNSPECIFIED, content_type: nil, **_other_kwargs
      return nil if data == UNSPECIFIED
      return nil unless text_content_type? content_type
      { content: data.to_s, content_type: content_type }
    end

    private

    def text_content_type? content_type
      content_type&.media_type == "text" ||
        content_type&.media_type == "application" && content_type&.subtype == "octet-stream"
    end
  end
end
