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
    ##
    # Decode an event from the given input JSON string.
    #
    # See {CloudEvents::Format#decode_event} for details.
    # This formatter determines whether to operate by checking the subtype
    # format.
    #
    # @param input [String] The input as a string.
    # @param content_type [CloudEvents::ContentType,nil] The input content
    #     type, or `nil` if none is available.
    # @return [CloudEvents::Event] if decoding succeeded.
    # @return [nil] if a different formatter should be used.
    #
    def decode_event input, content_type, **_other_kwargs
      return nil unless content_type&.subtype_format == "json"
      structure = ::JSON.parse input
      decode_hash_structure structure
    end

    ##
    # Encode an event to a JSON string.
    #
    # See {CloudEvents::Format#encode_event} for details.
    #
    # @param event [CloudEvents::Event] The input event.
    # @param sort [boolean] Whether to sort keys of the JSON output.
    # @return [Array(String,CloudEvents::ContentType)] if encoding succeeded.
    #
    def encode_event event, sort: false, **_other_kwargs
      structure = encode_hash_structure event
      structure = sort_keys structure if sort
      str = ::JSON.dump structure
      content_type = ContentType.new "application/cloudevents+json; charset=#{charset_of str}"
      [str, content_type]
    end

    ##
    # Decode a batch of events from the given input JSON string.
    #
    # See {CloudEvents::Format#decode_batch} for details.
    # This formatter determines whether to operate by checking the subtype
    # format.
    #
    # @param input [String] The input as a string.
    # @param content_type [CloudEvents::ContentType,nil] The input content
    #     type, or `nil` if none is available.
    # @return [Array<CloudEvents::Event>] if decoding succeeded.
    # @return [nil] if a different formatter should be used.
    #
    def decode_batch input, content_type, **_other_kwargs
      return nil unless content_type&.subtype_format == "json"
      structure_array = Array(::JSON.parse(input))
      structure_array.map do |structure|
        decode_hash_structure structure
      end
    end

    ##
    # Encode a batch of events to a JSON formatted string.
    #
    # See {CloudEvents::Format#encode_batch} for details.
    #
    # @param events [Array<CloudEvents::Event>] An array of input events.
    # @param sort [boolean] Whether to sort keys of the JSON output.
    # @return [Array(String,CloudEvents::ContentType)] if encoding succeeded.
    #
    def encode_batch events, sort: false, **_other_kwargs
      structure_array = Array(events).map do |event|
        structure = encode_hash_structure event
        sort ? sort_keys(structure) : structure
      end
      str = ::JSON.dump structure_array
      content_type = ContentType.new "application/cloudevents-batch+json; charset=#{charset_of str}"
      [str, content_type]
    end

    ##
    # Decode an event data object from a JSON formatted string.
    #
    # See {CloudEvents::Format#decode_data} for details.
    # This formatter determines whether to operate by checking the given
    # content type for JSON subtype markers.
    #
    # @param data [String] The input data string.
    # @param content_type [CloudEvents::ContentType,nil] The input content
    #     type, or `nil` if none is available.
    # @return [Array(Object,CloudEvents::ContentType)] if decoding succeeded.
    # @return [nil] if a different formatter should be used.
    #
    def decode_data data, content_type, **_other_kwargs
      return nil unless content_type&.subtype_base == "json" || content_type&.subtype_format == "json"
      [::JSON.parse(data), content_type]
    end

    ##
    # Encode an event data object to a JSON formatted string.
    #
    # See {CloudEvents::Format#encode_data} for details.
    # The input is a Ruby object that can be interpreted as JSON. Most Ruby
    # objects will work, but normally it will be a JSON value type comprising
    # hashes, arrays, strings, numbers, booleans, or nil.
    # This formatter determines whether to operate by checking the given
    # content type for JSON subtype markers.
    #
    # @param data [Object] A data object to encode.
    # @param content_type [CloudEvents::ContentType,nil] The input content
    #     type, or `nil` if none is available.
    # @param sort [boolean] Whether to sort keys of the JSON output.
    # @return [Array(String,CloudEvents::ContentType)] if encoding succeeded.
    # @return [nil] if a different formatter should be used.
    #
    def encode_data data, content_type, sort: false, **_other_kwargs
      return nil unless content_type&.subtype_base == "json" || content_type&.subtype_format == "json"
      data = sort_keys data if sort
      [::JSON.dump(data), content_type]
    end

    ##
    # Decode a single event from a hash data structure with keys and types
    # conforming to the JSON envelope.
    #
    # @private
    #
    # @param structure [Hash] An input hash.
    # @return [CloudEvents::Event]
    #
    def decode_hash_structure structure
      spec_version = structure["specversion"].to_s
      case spec_version
      when "0.3"
        decode_hash_structure_v0 structure
      when /^1(\.|$)/
        decode_hash_structure_v1 structure
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

    def decode_hash_structure_v0 structure
      data = structure["data"]
      if data.is_a? ::String
        content_type = ContentType.new structure["datacontenttype"] rescue nil
        if content_type&.subtype_base == "json" || content_type&.subtype_format == "json"
          structure = structure.dup
          structure["data"] = ::JSON.parse data rescue data
          structure["datacontenttype"] = content_type
        end
      end
      Event::V0.new attributes: structure
    end

    def decode_hash_structure_v1 structure
      if structure.key? "data_base64"
        structure = structure.dup
        structure["data"] = ::Base64.decode64 structure.delete "data_base64"
        structure["datacontenttype"] ||= "application/octet-stream"
      end
      Event::V1.new attributes: structure
    end

    def encode_hash_structure_v0 event
      structure = event.to_h
      data = event.data
      content_type = event.data_content_type
      if data.is_a?(::String) && (content_type&.subtype_base == "json" || content_type&.subtype_format == "json")
        structure["data"] = ::JSON.parse data rescue data
      end
      structure
    end

    def encode_hash_structure_v1 event
      structure = event.to_h
      data = structure["data"]
      if data.is_a?(::String) && data.encoding == ::Encoding::ASCII_8BIT
        structure.delete "data"
        structure["data_base64"] = ::Base64.encode64 data
      end
      structure
    end
  end
end
