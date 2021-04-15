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
    # Returns a default binding, with JSON supported.
    #
    def self.default
      @default ||= begin
        http_binding = new
        json_format = JsonFormat.new
        http_binding.register_structured_formatter "json", json_format
        http_binding.register_batched_formatter "json", json_format
        http_binding
      end
    end

    ##
    # Create an empty HTTP binding.
    #
    def initialize
      @structured_formatters = {}
      @batched_formatters = {}
    end

    ##
    # Register a formatter for the given type.
    #
    # A formatter must respond to the methods `#encode` and `#decode`. See
    # {CloudEvents::JsonFormat} for an example.
    #
    # @param type [String] The subtype format that should be handled by
    #     this formatter.
    # @param formatter [Object] The formatter object.
    # @return [self]
    #
    def register_structured_formatter type, formatter
      formatters = @structured_formatters[type.to_s.strip.downcase] ||= []
      formatters << formatter unless formatters.include? formatter
      self
    end

    ##
    # Register a batch formatter for the given type.
    #
    # A batch formatter must respond to the methods `#encode_batch` and
    # `#decode_batch`. See {CloudEvents::JsonFormat} for an example.
    #
    # @param type [String] The subtype format that should be handled by
    #     this formatter.
    # @param formatter [Object] The formatter object.
    # @return [self]
    #
    def register_batched_formatter type, formatter
      formatters = @batched_formatters[type.to_s.strip.downcase] ||= []
      formatters << formatter unless formatters.include? formatter
      self
    end

    ##
    # Decode an event from the given Rack environment hash. Following the
    # CloudEvents spec, this chooses a handler based on the Content-Type of
    # the request.
    #
    # @param env [Hash] The Rack environment.
    # @param format_args [keywords] Extra args to pass to the formatter.
    # @return [CloudEvents::Event] if the request includes a single structured
    #     or binary event.
    # @return [Array<CloudEvents::Event>] if the request includes a batch of
    #     structured events.
    # @return [nil] if the request was not recognized as a CloudEvent.
    #
    def decode_rack_env env, **format_args
      content_type_header = env["CONTENT_TYPE"]
      content_type = ContentType.new content_type_header if content_type_header
      input = env["rack.input"]
      if input && content_type&.media_type == "application"
        case content_type.subtype_base
        when "cloudevents"
          content = read_with_charset input, content_type.charset
          return decode_structured_content content, content_type.subtype_format, **format_args
        when "cloudevents-batch"
          content = read_with_charset input, content_type.charset
          return decode_batched_content content, content_type.subtype_format, **format_args
        end
      end
      decode_binary_content env, content_type
    end

    ##
    # Decode a single event from the given content data. This should be
    # passed the request body, if the Content-Type is of the form
    # `application/cloudevents+format`.
    #
    # @param input [String] The string content.
    # @param format [String] The format code (e.g. "json").
    # @param format_args [keywords] Extra args to pass to the formatter.
    # @return [CloudEvents::Event]
    #
    def decode_structured_content input, format, **format_args
      handlers = @structured_formatters[format] || []
      handlers.reverse_each do |handler|
        event = handler.decode input, **format_args
        return event if event
      end
      raise HttpContentError, "Unknown cloudevents format: #{format.inspect}"
    end

    ##
    # Decode a batch of events from the given content data. This should be
    # passed the request body, if the Content-Type is of the form
    # `application/cloudevents-batch+format`.
    #
    # @param input [String] The string content.
    # @param format [String] The format code (e.g. "json").
    # @param format_args [keywords] Extra args to pass to the formatter.
    # @return [Array<CloudEvents::Event>]
    #
    def decode_batched_content input, format, **format_args
      handlers = @batched_formatters[format] || []
      handlers.reverse_each do |handler|
        events = handler.decode_batch input, **format_args
        return events if events
      end
      raise HttpContentError, "Unknown cloudevents batch format: #{format.inspect}"
    end

    ##
    # Decode an event from the given Rack environment in binary content mode.
    #
    # @param env [Hash] Rack environment hash.
    # @param content_type [CloudEvents::ContentType] the content type from the
    #     Rack environment.
    # @return [CloudEvents::Event] if a CloudEvent could be decoded from the
    #     Rack environment.
    # @return [nil] if the Rack environment does not indicate a CloudEvent
    #
    def decode_binary_content env, content_type
      spec_version = env["HTTP_CE_SPECVERSION"]
      return nil if spec_version.nil?
      raise SpecVersionError, "Unrecognized specversion: #{spec_version}" unless spec_version == "1.0"
      input = env["rack.input"]
      data = read_with_charset input, content_type&.charset if input
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

    ##
    # Encode a single event to content data in the given format.
    #
    # The result is a two-element array where the first element is a headers
    # list (as defined in the Rack specification) and the second is a string
    # containing the HTTP body content. The headers list will contain only
    # one header, a `Content-Type` whose value is of the form
    # `application/cloudevents+format`.
    #
    # @param event [CloudEvents::Event] The event.
    # @param format [String] The format code (e.g. "json")
    # @param format_args [keywords] Extra args to pass to the formatter.
    # @return [Array(headers,String)]
    #
    def encode_structured_content event, format, **format_args
      handlers = @structured_formatters[format] || []
      handlers.reverse_each do |handler|
        content = handler.encode event, **format_args
        return [{ "Content-Type" => "application/cloudevents+#{format}" }, content] if content
      end
      raise HttpContentError, "Unknown cloudevents format: #{format.inspect}"
    end

    ##
    # Encode a batch of events to content data in the given format.
    #
    # The result is a two-element array where the first element is a headers
    # list (as defined in the Rack specification) and the second is a string
    # containing the HTTP body content. The headers list will contain only
    # one header, a `Content-Type` whose value is of the form
    # `application/cloudevents-batch+format`.
    #
    # @param events [Array<CloudEvents::Event>] The batch of events.
    # @param format [String] The format code (e.g. "json").
    # @param format_args [keywords] Extra args to pass to the formatter.
    # @return [Array(headers,String)]
    #
    def encode_batched_content events, format, **format_args
      handlers = @batched_formatters[format] || []
      handlers.reverse_each do |handler|
        content = handler.encode_batch events, **format_args
        return [{ "Content-Type" => "application/cloudevents-batch+#{format}" }, content] if content
      end
      raise HttpContentError, "Unknown cloudevents format: #{format.inspect}"
    end

    ##
    # Encode an event to content and headers, in binary content mode.
    #
    # The result is a two-element array where the first element is a headers
    # list (as defined in the Rack specification) and the second is a string
    # containing the HTTP body content.
    #
    # @param event [CloudEvents::Event] The event.
    # @return [Array(headers,String)]
    #
    def encode_binary_content event
      headers = {}
      body = nil
      event.to_h.each do |key, value|
        case key
        when "data"
          body = value
        when "datacontenttype"
          headers["Content-Type"] = value
        else
          headers["CE-#{key}"] = percent_encode value
        end
      end
      case body
      when ::String
        headers["Content-Type"] ||= string_content_type body
      when nil
        headers.delete "Content-Type"
      else
        body = ::JSON.dump body
        headers["Content-Type"] ||= "application/json; charset=#{body.encoding.name.downcase}"
      end
      [headers, body]
    end

    ##
    # Decode a percent-encoded string to a UTF-8 string.
    #
    # @param str [String] Incoming ascii string from an HTTP header, with one
    #     cycle of percent-encoding.
    # @return [String] Resulting decoded string in UTF-8.
    #
    def percent_decode str
      decoded_str = str.gsub(/%[0-9a-fA-F]{2}/) { |m| [m[1..-1].to_i(16)].pack "C" }
      decoded_str.force_encoding ::Encoding::UTF_8
    end

    ##
    # Transcode an arbitrarily-encoded string to UTF-8, then percent-encode
    # non-printing and non-ascii characters to result in an ASCII string
    # suitable for setting as an HTTP header value.
    #
    # @param str [String] Incoming arbitrary string that can be represented
    #     in UTF-8.
    # @return [String] Resulting encoded string in ASCII.
    #
    def percent_encode str
      arr = []
      utf_str = str.to_s.encode ::Encoding::UTF_8
      utf_str.each_byte do |byte|
        if byte >= 33 && byte <= 126 && byte != 37
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

    def read_with_charset io, charset
      str = io.read
      if charset
        begin
          str.force_encoding charset
        rescue ::ArgumentError
          # Do nothing for now if the charset is unrecognized
        end
      end
      str
    end

    def string_content_type str
      if str.encoding == ::Encoding.ASCII_8BIT
        "application/octet-stream"
      else
        "text/plain; charset=#{str.encoding.name.downcase}"
      end
    end
  end
end
