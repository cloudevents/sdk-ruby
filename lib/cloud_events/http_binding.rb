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
        http_binding.default_encoder_name = JSON_FORMAT
        http_binding
      end
    end

    ##
    # Create an empty HTTP binding.
    #
    def initialize
      @event_decoders = []
      @event_encoders = {}
      @data_decoders = [DefaultDataFormat]
      @data_encoders = [DefaultDataFormat]
      @default_encoder_name = nil
    end

    ##
    # Register a formatter for all operations it supports, based on which
    # methods are implemented by the formatter object. See
    # {CloudEvents::Format} for a list of possible methods.
    #
    # @param formatter [Object] The formatter
    # @param name [String] The encoder name under which this formatter will
    #     register its encode operations. Optional. If not specified, any event
    #     encoder will _not_ be registered.
    #
    def register_formatter formatter, name = nil
      name = name.to_s.strip.downcase if name
      decode_event = formatter.respond_to? :decode_event
      encode_event = name if formatter.respond_to? :encode_event
      decode_data = formatter.respond_to? :decode_data
      encode_data = formatter.respond_to? :encode_data
      register_formatter_methods formatter,
                                 decode_event: decode_event,
                                 encode_event: encode_event,
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
    # @param decode_data [boolean] If true, register the formatter's
    #     {CloudEvents::Format#decode_data} method.
    # @param encode_data [boolean] If true, register the formatter's
    #     {CloudEvents::Format#encode_data} method.
    #
    def register_formatter_methods formatter,
                                   decode_event: false,
                                   encode_event: nil,
                                   decode_data: false,
                                   encode_data: false
      @event_decoders << formatter if decode_event
      if encode_event
        formatters = @event_encoders[encode_event] ||= []
        formatters << formatter unless formatters.include? formatter
      end
      @data_decoders << formatter if decode_data
      @data_encoders << formatter if encode_data
      self
    end

    ##
    # The name of the encoder to use if none is specified
    # @return [String,nil]
    #
    attr_accessor :default_encoder_name

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
      content_type_string = env["CONTENT_TYPE"]
      content_type = ContentType.new content_type_string if content_type_string
      content = read_with_charset env["rack.input"], content_type&.charset
      result = decode_binary_content content, content_type, env
      result ||= decode_structured_content content, content_type, allow_opaque, **format_args
      if result.nil?
        content_type_string = content_type_string ? content_type_string.inspect : "not present"
        raise NotCloudEventError, "Content-Type is #{content_type_string}, and CE-SpecVersion is not present"
      end
      result
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
        if event.is_a? ::Array
          raise ::ArgumentError, "Encoding a batch requires structured_format"
        end
        encode_binary_content event, **format_args
      else
        structured_format = default_encoder_name if structured_format == true
        raise ::ArgumentError, "Format name not specified, and no default is set" unless structured_format
        case event
        when ::Array
          encode_batched_content event, structured_format, **format_args
        when Event
          encode_structured_content event, structured_format, **format_args
        else
          raise ::ArgumentError, "Unknown event type: #{event.class}"
        end
      end
    end

    ##
    # Encode a single event in structured content mode in the given format.
    #
    # @deprecated Will be removed in version 1.0. Use {#encode_event} instead.
    #
    # @param event [CloudEvents::Event] The event.
    # @param format_name [String] The format name.
    # @param format_args [keywords] Extra args to pass to the formatter.
    # @return [Array(headers,String)]
    #
    def encode_structured_content event, format_name, **format_args
      Array(@event_encoders[format_name]).reverse_each do |handler|
        result = handler.encode_event event: event, **format_args
        if result&.key?(:content) && result&.key?(:content_type)
          return [{ "Content-Type" => result[:content_type].to_s }, result[:content]]
        end
      end
      raise ::ArgumentError, "Unknown format name: #{format_name.inspect}"
    end

    ##
    # Encode a batch of events in structured content mode in the given format.
    #
    # @deprecated Will be removed in version 1.0. Use {#encode_event} instead.
    #
    # @param event_batch [Array<CloudEvents::Event>] The batch of events.
    # @param format_name [String] The format name.
    # @param format_args [keywords] Extra args to pass to the formatter.
    # @return [Array(headers,String)]
    #
    def encode_batched_content event_batch, format_name, **format_args
      Array(@event_encoders[format_name]).reverse_each do |handler|
        result = handler.encode_event event_batch: event_batch, **format_args
        if result&.key?(:content) && result&.key?(:content_type)
          return [{ "Content-Type" => result[:content_type].to_s }, result[:content]]
        end
      end
      raise ::ArgumentError, "Unknown format name: #{format_name.inspect}"
    end

    ##
    # Encode an event in binary content mode.
    #
    # @deprecated Will be removed in version 1.0. Use {#encode_event} instead.
    #
    # @param event [CloudEvents::Event] The event.
    # @param format_args [keywords] Extra args to pass to the formatter.
    # @return [Array(headers,String)]
    #
    def encode_binary_content event, **format_args
      headers = {}
      event.to_h.each do |key, value|
        unless ["data", "datacontenttype"].include? key
          headers["CE-#{key}"] = percent_encode value
        end
      end
      body, content_type = encode_data event.spec_version, event.data, event.data_content_type, **format_args
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
    def decode_structured_content content, content_type, allow_opaque, **format_args
      @event_decoders.reverse_each do |decoder|
        result = decoder.decode_event content: content, content_type: content_type, **format_args
        event = result[:event] || result[:event_batch]
        return event if event
      end
      if content_type&.media_type == "application" &&
         ["cloudevents", "cloudevents-batch"].include?(content_type.subtype_base)
        return Event::Opaque.new content, content_type if allow_opaque
        raise UnsupportedFormatError, "Unknown cloudevents content type: #{content_type}"
      end
      nil
    end

    ##
    # Decode an event from the given Rack environment in binary content mode.
    #
    def decode_binary_content content, content_type, env
      spec_version = env["HTTP_CE_SPECVERSION"]
      return nil unless spec_version
      unless spec_version =~ /^0\.3|1(\.|$)/
        raise SpecVersionError, "Unrecognized specversion: #{spec_version}"
      end
      data, content_type = decode_data spec_version, content, content_type
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
    end

    def decode_data spec_version, content, content_type, **format_args
      @data_decoders.reverse_each do |handler|
        result = handler.decode_data spec_version: spec_version,
                                     content: content,
                                     content_type: content_type,
                                     **format_args
        if result&.key?(:data) && result&.key?(:content_type)
          return [result[:data], result[:content_type]]
        end
      end
      raise "Should not get here"
    end

    def encode_data spec_version, data_obj, content_type, **format_args
      @data_encoders.reverse_each do |handler|
        result = handler.encode_data spec_version: spec_version,
                                     data: data_obj,
                                     content_type: content_type,
                                     **format_args
        if result&.key?(:content) && result&.key?(:content_type)
          return [result[:content], result[:content_type]]
        end
      end
      raise "Should not get here"
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

    # @private
    module DefaultDataFormat
      # @private
      def self.decode_data content: nil, content_type: nil, **_extra_kwargs
        { data: content, content_type: content_type }
      end

      # @private
      def self.encode_data data: nil, content_type: nil, **_extra_kwargs
        content = data.to_s
        content_type ||=
          if content.encoding == ::Encoding::ASCII_8BIT
            "application/octet-stream"
          else
            "text/plain; charset=#{content.encoding.name.downcase}"
          end
        { content: content, content_type: content_type }
      end
    end
  end
end
