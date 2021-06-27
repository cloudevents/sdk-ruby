# frozen_string_literal: true

require "base64"
require "json"

module CloudEvents
  ##
  # An implementation of JSON format and JSON batch format.
  #
  # Supports the CloudEvents 0.3 and CloudEvents 1.0 variants of this format.
  # See https://github.com/cloudevents/spec/blob/v0.3/json-format.md and
  # https://github.com/cloudevents/spec/blob/v1.0/json-format.md.
  #
  class JsonFormat
    # @private
    UNSPECIFIED = ::Object.new.freeze

    ##
    # Decode an event or batch from the given input JSON string.
    # See {CloudEvents::Format#decode_event} for a general description.
    #
    # Expects `:content` and `:content_type` arguments, and will decline the
    # request unless both are provided.
    #
    # If decoding succeeded, returns a hash with _one of_ the following keys:
    #
    # * `:event` ({CloudEvents::Event}) A single event decoded from the input.
    # * `:event_batch` (Array of {CloudEvents::Event}) A batch of events
    #   decoded from the input.
    #
    # @param content [String] Serialized content to decode.
    # @param content_type [CloudEvents::ContentType] The input content type.
    # @return [Hash] if accepting the request.
    # @return [nil] if declining the request.
    # @raise [CloudEvents::FormatSyntaxError] if the JSON could not be parsed
    # @raise [CloudEvents::SpecVersionError] if an unsupported specversion is
    #     found.
    #
    def decode_event content: nil, content_type: nil, **_other_kwargs
      return nil unless content && content_type&.media_type == "application" && content_type&.subtype_format == "json"
      case content_type.subtype_base
      when "cloudevents"
        event = decode_hash_structure ::JSON.parse(content), charset_of(content)
        { event: event }
      when "cloudevents-batch"
        charset = charset_of content
        batch = Array(::JSON.parse(content)).map do |structure|
          decode_hash_structure structure, charset
        end
        { event_batch: batch }
      end
    rescue ::JSON::JSONError
      raise FormatSyntaxError, "JSON syntax error"
    end

    ##
    # Encode an event or batch to a JSON string. This formatter should be able
    # to handle any event.
    # See {CloudEvents::Format#decode_event} for a general description.
    #
    # Expects _either_ the `:event` _or_ the `:event_batch` argument, but not
    # both, and will decline the request unless exactly one is provided.
    #
    # If encoding succeeded, returns a hash with the following keys:
    #
    # * `:content` (String) The serialized form of the event or batch.
    # * `:content_type` ({CloudEvents::ContentType}) The content type for the
    #   output.
    #
    # @param event [CloudEvents::Event] An event to encode.
    # @param event_batch [Array<CloudEvents::Event>] An event batch to encode.
    # @param sort [boolean] Whether to sort keys of the JSON output.
    # @return [Hash] if accepting the request.
    # @return [nil] if declining the request.
    #
    def encode_event event: nil, event_batch: nil, sort: false, **_other_kwargs
      if event && !event_batch
        structure = encode_hash_structure event
        structure = sort_keys structure if sort
        subtype = "cloudevents"
      elsif event_batch && !event
        structure = event_batch.map do |elem|
          structure_elem = encode_hash_structure elem
          sort ? sort_keys(structure_elem) : structure_elem
        end
        subtype = "cloudevents-batch"
      else
        return nil
      end
      content = ::JSON.dump structure
      content_type = ContentType.new "application/#{subtype}+json; charset=#{charset_of content}"
      { content: content, content_type: content_type }
    end

    ##
    # Decode an event data object from a JSON formatted string.
    # See {CloudEvents::Format#decode_data} for a general description.
    #
    # Expects `:spec_version`, `:content` and `:content_type` arguments, and
    # will decline the request unless all three are provided.
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
    # @raise [CloudEvents::FormatSyntaxError] if the JSON could not be parsed.
    # @raise [CloudEvents::SpecVersionError] if an unsupported specversion is
    #     found.
    #
    def decode_data spec_version: nil, content: nil, content_type: nil, **_other_kwargs
      return nil unless spec_version
      return nil unless content
      return nil unless content_type&.subtype_base == "json" || content_type&.subtype_format == "json"
      unless spec_version =~ /^0\.3|1(\.|$)/
        raise SpecVersionError, "Unrecognized specversion: #{spec_version}"
      end
      data = ::JSON.parse content
      { data: data, content_type: content_type }
    rescue ::JSON::JSONError
      raise FormatSyntaxError, "JSON syntax error"
    end

    ##
    # Encode an event data object to a JSON formatted string.
    # See {CloudEvents::Format#encode_data} for a general description.
    #
    # Expects `:spec_version`, `:data` and `:content_type` arguments, and will
    # decline the request unless all three are provided.
    # The `:data` object can be any Ruby object that can be interpreted as
    # JSON. Most Ruby objects will work, but normally it will be a JSON value
    # type comprising hashes, arrays, strings, numbers, booleans, or nil.
    #
    # If decoding succeeded, returns a hash with the following keys:
    #
    # * `:content` (String) The serialized form of the data.
    # * `:content_type` ({CloudEvents::ContentType}) The content type for the
    #   output.
    #
    # @param data [Object] A data object to encode.
    # @param content_type [CloudEvents::ContentType] The input content type
    # @param sort [boolean] Whether to sort keys of the JSON output.
    # @return [Hash] if accepting the request.
    # @return [nil] if declining the request.
    #
    def encode_data spec_version: nil, data: UNSPECIFIED, content_type: nil, sort: false, **_other_kwargs
      return nil unless spec_version
      return nil if data == UNSPECIFIED
      return nil unless content_type&.subtype_base == "json" || content_type&.subtype_format == "json"
      unless spec_version =~ /^0\.3|1(\.|$)/
        raise SpecVersionError, "Unrecognized specversion: #{spec_version}"
      end
      data = sort_keys data if sort
      content = ::JSON.dump data
      { content: content, content_type: content_type }
    end

    ##
    # Decode a single event from a hash data structure with keys and types
    # conforming to the JSON envelope.
    #
    # @private
    #
    # @param structure [Hash] An input hash.
    # @param charset [String] The charset.
    # @return [CloudEvents::Event]
    #
    def decode_hash_structure structure, charset = nil
      spec_version = structure["specversion"].to_s
      case spec_version
      when "0.3"
        decode_hash_structure_v0 structure, charset
      when /^1(\.|$)/
        decode_hash_structure_v1 structure, charset
      else
        raise SpecVersionError, "Unrecognized specversion: #{spec_version}"
      end
    end

    ##
    # Encode a single event to a hash data structure with keys and types
    # conforming to the JSON envelope.
    #
    # @private
    #
    # @param event [CloudEvents::Event] An input event.
    # @return [String] The hash structure.
    #
    def encode_hash_structure event
      case event
      when Event::V0
        encode_hash_structure_v0 event
      when Event::V1
        encode_hash_structure_v1 event
      else
        raise SpecVersionError, "Unrecognized specversion: #{event.spec_version}"
      end
    end

    private

    def sort_keys obj
      return obj unless obj.is_a? ::Hash
      result = {}
      obj.keys.sort.each do |key|
        result[key] = sort_keys obj[key]
      end
      result
    end

    def charset_of str
      encoding = str.encoding
      if encoding == ::Encoding::ASCII_8BIT
        "binary"
      else
        encoding.name.downcase
      end
    end

    def decode_hash_structure_v0 structure, charset
      unless structure.key? "datacontenttype"
        structure = structure.dup
        content_type = "application/json"
        content_type = "#{content_type}; charset=#{charset}" if charset
        structure["datacontenttype"] = content_type
      end
      Event::V0.new attributes: structure
    end

    def decode_hash_structure_v1 structure, charset
      if structure.key? "data_base64"
        structure = structure.dup
        structure["data"] = ::Base64.decode64 structure.delete "data_base64"
        structure["datacontenttype"] ||= "application/octet-stream"
      elsif !structure.key? "datacontenttype"
        structure = structure.dup
        content_type = "application/json"
        content_type = "#{content_type}; charset=#{charset}" if charset
        structure["datacontenttype"] = content_type
      end
      Event::V1.new attributes: structure
    end

    def encode_hash_structure_v0 event
      structure = event.to_h
      structure["datacontenttype"] ||= "application/json"
      structure
    end

    def encode_hash_structure_v1 event
      structure = event.to_h
      data = structure["data"]
      if data.is_a?(::String) && data.encoding == ::Encoding::ASCII_8BIT
        structure.delete "data"
        structure["data_base64"] = ::Base64.encode64 data
        structure["datacontenttype"] ||= "application/octet-stream"
      else
        structure["datacontenttype"] ||= "application/json"
      end
      structure
    end
  end
end
