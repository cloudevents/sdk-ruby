# frozen_string_literal: true

module CloudEvents
  ##
  # HTTP binding for CloudEvents.
  #
  # This class implements HTTP binding, including unmarshalling of events from
  # Rack environment data, and marshalling of events to Rack environment data.
  # It supports binary (i.e. header-based) HTTP content, as well as structured
  # (body-based) content that can delegate to formatters such as JSON.
  #
  # Supports the CloudEvents 0.3 and CloudEvents 1.0 variants of this format.
  # See https://github.com/cloudevents/spec/blob/v0.3/http-transport-binding.md
  # and https://github.com/cloudevents/spec/blob/v1.0/http-protocol-binding.md.
  #
  class HttpBinding
    ##
    # The name of the JSON decoder/encoder
    # @return [String]
    #
    JSON_FORMAT = "json"

    ##
    # Returns a default HTTP binding, including support for JSON format.
    #
    def self.default
      @default ||= begin
        http_binding = new
        json_format = JsonFormat.new
        http_binding.register_formatter json_format, JSON_FORMAT
        http_binding.default_structured_encoder = JSON_FORMAT
        http_binding.default_batched_encoder = JSON_FORMAT
        http_binding
      end
    end

    ##
    # Create an empty HTTP binding.
    #
    def initialize
      @event_decoders = []
      @event_encoders = {}
      @batch_decoders = []
      @batch_encoders = {}
      @data_decoders = []
      @data_encoders = []
      @default_structured_encoder = nil
      @default_batched_encoder = nil
    end

    ##
    # Register a formatter for all operations it supports, based on which
    # methods are implemented by the formatter object. See
    # {CloudEvents::Format} for a list of possible methods.
    #
    # @param formatter [Object] The formatter
    # @param name [String] The encoder name under which this formatter will
    #     register its encode operations. Optional. If not specified, no
    #     event or batch encoders will be registered.
    #
    def register_formatter formatter, name = nil
      name = name.to_s.strip.downcase if name
      decode_event = formatter.respond_to? :decode_event
      encode_event = name if formatter.respond_to? :encode_event
      decode_batch = formatter.respond_to? :decode_batch
      encode_batch = name if formatter.respond_to? :encode_batch
      decode_data = formatter.respond_to? :decode_data
      encode_data = formatter.respond_to? :encode_data
      register_formatter_methods formatter,
                                 decode_event: decode_event,
                                 encode_event: encode_event,
                                 decode_batch: decode_batch,
                                 encode_batch: encode_batch,
                                 decode_data: decode_data,
                                 encode_data: encode_data
      self
    end

    ##
    # Registers the given formatter for the given operations. Some arguments
    # are activated by passing `true`, whereas those that rely on a format name
    # are activated by passing in a name string.
    #
    # @param formatter [Object] The formatter
    # @param decode_event [boolean] If true, register the formatter's
    #     {CloudEvents::Format#decode_event} method.
    # @param encode_event [String] If set to a string, use the formatter's
    #     {CloudEvents::Format#encode_event} method when that name is requested.
    # @param decode_batch [boolean] If true, register the formatter's
    #     {CloudEvents::Format#decode_batch} method.
    # @param encode_batch [String] If set to a string, use the formatter's
    #     {CloudEvents::Format#encode_batch} method when that name is requested.
    # @param decode_data [boolean] If true, register the formatter's
    #     {CloudEvents::Format#decode_data} method.
    # @param encode_data [boolean] If true, register the formatter's
    #     {CloudEvents::Format#encode_data} method.
    #
    def register_formatter_methods formatter,
                                   decode_event: false,
                                   encode_event: nil,
                                   decode_batch: false,
                                   encode_batch: nil,
                                   decode_data: false,
                                   encode_data: false
      @event_decoders << formatter if decode_event
      add_named_formatter @event_encoders, formatter, encode_event
      @batch_decoders << formatter if decode_batch
      add_named_formatter @batch_encoders, formatter, encode_batch
      @data_decoders << formatter if decode_data
      @data_encoders << formatter if encode_data
      self
    end

    ##
    # The name of the structured encoder to use if none is specified
    # @return [String,nil]
    #
    attr_accessor :default_structured_encoder

    ##
    # The name of the batched encoder to use if none is specified
    # @return [String,nil]
    #
    attr_accessor :default_batched_encoder

    ##
    # Decode an event from the given Rack environment hash. Following the
    # CloudEvents spec, this chooses a handler based on the Content-Type of
    # the request.
    #
    # @param env [Hash] The Rack environment.
    # @param allow_opaque [boolean] If true, returns opaque event objects if
    #     the input is not in a recognized format. If false, raises
    #     {CloudEvents::UnsupportedFormatError} in that case. Default is false.
    # @param format_args [keywords] Extra args to pass to the formatter.
    # @return [CloudEvents::Event] if the request includes a single structured
    #     or binary event.
    # @return [Array<CloudEvents::Event>] if the request includes a batch of
    #     structured events.
    # @raise [CloudEvents::CloudEventsError] if an event could not be decoded
    #     from the request.
    #
    def decode_rack_env env, allow_opaque: false, **format_args
      content_type_header = env["CONTENT_TYPE"]
      content_type = ContentType.new content_type_header if content_type_header
      if content_type&.media_type == "application"
        case content_type.subtype_base
        when "cloudevents"
          content = read_with_charset env["rack.input"], content_type.charset
          return decode_structured_content content, content_type, allow_opaque, **format_args
        when "cloudevents-batch"
          content = read_with_charset env["rack.input"], content_type.charset
          return decode_batched_content content, content_type, allow_opaque, **format_args
        end
      end
      decode_binary_content env, content_type
    end

    ##
    # Encode an event or batch of events into HTTP headers and body.
    #
    # You may provide an event, an array of events, or an opaque event. You may
    # also specify what content mode and format to use.
    #
    # The result is a two-element array where the first element is a headers
    # list (as defined in the Rack specification) and the second is a string
    # containing the HTTP body content. When using structured content mode, the
    # headers list will contain only a `Content-Type` header and the body will
    # contain the serialized event. When using binary mode, the header list
    # will contain the serialized event attributes and the body will contain
    # the serialized event data.
    #
    # @param event [CloudEvents::Event,Array<CloudEvents::Event>,CloudEvents::Event::Opaque]
    #     The event, batch, or opaque event.
    # @param structured_format [boolean,String] If given, the data will be
    #     encoded in structured content mode. You can pass a string to select
    #     a format name, or pass `true` to use the default format. If set to
    #     `false` (the default), the data will be encoded in binary mode.
    # @param format_args [keywords] Extra args to pass to the formatter.
    # @return [Array(headers,String)]
    #
    def encode_event event, structured_format: false, **format_args
      if event.is_a? Event::Opaque
        [{ "Content-Type" => event.content_type.to_s }, event.content]
      elsif !structured_format
        encode_binary_content event, **format_args
      elsif event.is_a? ::Array
        structured_format = default_batched_encoder if structured_format == true
        raise ArgumentError, "Format name not specified, and no default is set" unless structured_format
        encode_batched_content event, structured_format, **format_args
      elsif event.is_a? Event
        structured_format = default_structured_encoder if structured_format == true
        raise ArgumentError, "Format name not specified, and no default is set" unless structured_format
        encode_structured_content event, structured_format, **format_args
      else
        raise ArgumentError, "Unknown event type: #{event.class}"
      end
    end

    ##
    # Encode a single event in structured content mode in the given format.
    #
    # @deprecated Will be removed in vresion 1.0. Use encode_event instead.
    #
    # @private
    #
    # @param event [CloudEvents::Event] The event.
    # @param format [String] The format name.
    # @param format_args [keywords] Extra args to pass to the formatter.
    # @return [Array(headers,String)]
    #
    def encode_structured_content event, format, **format_args
      Array(@event_encoders[format]).reverse_each do |handler|
        result = handler.encode_event event, **format_args
        return [{ "Content-Type" => result[1].to_s }, result[0]] if result
      end
      raise ArgumentError, "Unknown format name: #{format.inspect}"
    end

    ##
    # Encode a batch of events in structured content mode in the given format.
    #
    # @deprecated Will be removed in vresion 1.0. Use encode_event instead.
    #
    # @private
    #
    # @param events [Array<CloudEvents::Event>] The batch of events.
    # @param format [String] The format name.
    # @param format_args [keywords] Extra args to pass to the formatter.
    # @return [Array(headers,String)]
    #
    def encode_batched_content events, format, **format_args
      Array(@batch_encoders[format]).reverse_each do |handler|
        result = handler.encode_batch events, **format_args
        return [{ "Content-Type" => result[1].to_s }, result[0]] if result
      end
      raise ArgumentError, "Unknown format name: #{format.inspect}"
    end

    ##
    # Encode an event in binary content mode.
    #
    # @deprecated Will be removed in vresion 1.0. Use encode_event instead.
    #
    # @private
    #
    # @param event [CloudEvents::Event] The event.
    # @param format_args [keywords] Extra args to pass to the formatter.
    # @return [Array(headers,String)]
    #
    def encode_binary_content event, **format_args
      headers = {}
      body = event.data
      content_type = event.data_content_type
      event.to_h.each do |key, value|
        unless ["data", "datacontenttype"].include? key
          headers["CE-#{key}"] = percent_encode value
        end
      end
      body, content_type = encode_data body, content_type, **format_args
      headers["Content-Type"] = content_type.to_s if content_type
      [headers, body]
    end

    ##
    # Decode a percent-encoded string to a UTF-8 string.
    #
    # @private
    #
    # @param str [String] Incoming ascii string from an HTTP header, with one
    #     cycle of percent-encoding.
    # @return [String] Resulting decoded string in UTF-8.
    #
    def percent_decode str
      str = str.gsub(/"((?:[^"\\]|\\.)*)"/) { ::Regexp.last_match(1).gsub(/\\(.)/, '\1') }
      decoded_str = str.gsub(/%[0-9a-fA-F]{2}/) { |m| [m[1..-1].to_i(16)].pack "C" }
      decoded_str.force_encoding ::Encoding::UTF_8
    end

    ##
    # Transcode an arbitrarily-encoded string to UTF-8, then percent-encode
    # non-printing and non-ascii characters to result in an ASCII string
    # suitable for setting as an HTTP header value.
    #
    # @private
    #
    # @param str [String] Incoming arbitrary string that can be represented
    #     in UTF-8.
    # @return [String] Resulting encoded string in ASCII.
    #
    def percent_encode str
      arr = []
      utf_str = str.to_s.encode ::Encoding::UTF_8
      utf_str.each_byte do |byte|
        if byte >= 33 && byte <= 126 && byte != 34 && byte != 37
          arr << byte
        else
          hi = byte / 16
          hi = hi > 9 ? 55 + hi : 48 + hi
          lo = byte % 16
          lo = lo > 9 ? 55 + lo : 48 + lo
          arr << 37 << hi << lo
        end
      end
      arr.pack "C*"
    end

    private

    def add_named_formatter collection, formatter, name
      return unless name
      formatters = collection[name] ||= []
      formatters << formatter unless formatters.include? formatter
    end

    ##
    # Decode a single event from the given request body and content type in
    # structured mode.
    #
    def decode_structured_content input, content_type, allow_opaque, **format_args
      @event_decoders.reverse_each do |decoder|
        event = decoder.decode_event input, content_type, **format_args
        return event if event
      end
      return Event::Opaque.new input, content_type, batch: false if allow_opaque
      raise UnsupportedFormatError, "Unknown cloudevents content type: #{content_type}"
    end

    ##
    # Decode a batch of events from the given request body and content type in
    # batched structured mode.
    #
    def decode_batched_content input, content_type, allow_opaque, **format_args
      @batch_decoders.reverse_each do |decoder|
        events = decoder.decode_batch input, content_type, **format_args
        return events if events
      end
      return Event::Opaque.new input, content_type, batch: true if allow_opaque
      raise UnsupportedFormatError, "Unknown cloudevents content type: #{content_type}"
    end

    ##
    # Decode an event from the given Rack environment in binary content mode.
    #
    def decode_binary_content env, content_type
      spec_version = env["HTTP_CE_SPECVERSION"]
      case spec_version
      when nil
        raise NotCloudEventError, "Content-Type is #{content_type}, and CE-SpecVersion is not present"
      when /^0\.3|1(\.|$)/
        data = read_with_charset env["rack.input"], content_type&.charset
        data, content_type = decode_data data, content_type if content_type
        attributes = { "spec_version" => spec_version, "data" => data }
        attributes["data_content_type"] = content_type if content_type
        omit_names = ["specversion", "spec_version", "data", "datacontenttype", "data_content_type"]
        env.each do |key, value|
          match = /^HTTP_CE_(\w+)$/.match key
          next unless match
          attr_name = match[1].downcase
          attributes[attr_name] = percent_decode value unless omit_names.include? attr_name
        end
        Event.create spec_version: spec_version, attributes: attributes
      else
        raise SpecVersionError, "Unrecognized specversion: #{spec_version}"
      end
    end

    def decode_data data_str, content_type, **format_args
      @data_decoders.reverse_each do |handler|
        result = handler.decode_data data_str, content_type, **format_args
        return result if result
      end
      [data_str, content_type]
    end

    def encode_data data_obj, content_type, **format_args
      @data_encoders.reverse_each do |handler|
        result = handler.encode_data data_obj, content_type, **format_args
        return result if result
      end
      return [nil, nil] if data_obj.nil?
      default_str = data_obj.to_s
      content_type ||=
        if default_str.encoding == ::Encoding::ASCII_8BIT
          "application/octet-stream"
        else
          "text/plain; charset=#{default_str.encoding.name.downcase}"
        end
      [default_str, content_type]
    end

    def read_with_charset io, charset
      return nil if io.nil?
      str = io.read
      if charset
        begin
          str.force_encoding charset
        rescue ::ArgumentError
          # Use binary for now if the charset is unrecognized
          str.force_encoding ::Encoding::ASCII_8BIT
        end
      end
      str
    end
  end
end
