# frozen_string_literal: true

module CloudEvents
  ##
  # Kafka protocol binding for CloudEvents.
  #
  # This class implements the Kafka protocol binding, including decoding of
  # events from Kafka message hashes, and encoding of events to Kafka message
  # hashes. It supports binary (header-based) and structured (body-based)
  # content modes that can delegate to formatters such as JSON.
  #
  # Supports CloudEvents 1.0 only.
  # See https://github.com/cloudevents/spec/blob/main/cloudevents/bindings/kafka-protocol-binding.md.
  #
  # Kafka messages are represented as plain Ruby Hashes with the keys:
  # - `key:` [String, nil] — the Kafka record key
  # - `value:` [String, nil] — the Kafka record value (body)
  # - `headers:` [Hash] — String => String header pairs
  #
  class KafkaBinding
    ##
    # The name of the JSON decoder/encoder.
    # @return [String]
    #
    JSON_FORMAT = "json"

    ##
    # The default key mapper for encoding.
    # Returns the `partitionkey` extension attribute from the event.
    # @return [Proc]
    #
    DEFAULT_KEY_MAPPER = ->(event) { event["partitionkey"] }

    ##
    # The default reverse key mapper for decoding.
    # Sets the `partitionkey` extension attribute from the Kafka record key.
    # Returns an empty hash if the key is nil.
    # @return [Proc]
    #
    DEFAULT_REVERSE_KEY_MAPPER = ->(key) { key.nil? ? {} : { "partitionkey" => key } }

    ##
    # Returns a default Kafka binding, including support for JSON format.
    #
    # @return [KafkaBinding]
    #
    def self.default
      @default ||= begin
        kafka_binding = new
        kafka_binding.register_formatter(JsonFormat.new, encoder_name: JSON_FORMAT)
        kafka_binding.default_encoder_name = JSON_FORMAT
        kafka_binding
      end
    end

    ##
    # Create an empty Kafka binding.
    #
    # @param key_mapper [Proc,nil] A callable `(event) -> String|nil` used
    #     to derive the Kafka record key when encoding. Defaults to
    #     {DEFAULT_KEY_MAPPER}. Set to `nil` to always produce a `nil` key.
    # @param reverse_key_mapper [Proc,nil] A callable `(key) -> Hash` used
    #     to derive attributes to merge into the event when decoding.
    #     Defaults to {DEFAULT_REVERSE_KEY_MAPPER}. Set to `nil` to skip
    #     key-to-attribute mapping.
    #
    def initialize(key_mapper: DEFAULT_KEY_MAPPER, reverse_key_mapper: DEFAULT_REVERSE_KEY_MAPPER)
      @key_mapper = key_mapper
      @reverse_key_mapper = reverse_key_mapper
      @event_decoders = Format::Multi.new do |result|
        result&.key?(:event) ? result : nil
      end
      @event_encoders = {}
      @data_decoders = Format::Multi.new do |result|
        result&.key?(:data) && result.key?(:content_type) ? result : nil
      end
      @data_encoders = Format::Multi.new do |result|
        result&.key?(:content) && result.key?(:content_type) ? result : nil
      end
      text_format = TextFormat.new
      @data_decoders.formats.replace([text_format, HttpBinding::DefaultDataFormat])
      @data_encoders.formats.replace([text_format, HttpBinding::DefaultDataFormat])
      @default_encoder_name = nil
    end

    ##
    # Register a formatter for all operations it supports, based on which
    # methods are implemented by the formatter object. See
    # {CloudEvents::Format} for a list of possible methods.
    #
    # @param formatter [Object] The formatter.
    # @param encoder_name [String] The encoder name under which this
    #     formatter will register its encode operations. Optional. If not
    #     specified, any event encoder will _not_ be registered.
    # @return [self]
    #
    def register_formatter(formatter, encoder_name: nil)
      encoder_name = encoder_name.to_s.strip.downcase if encoder_name
      decode_event = formatter.respond_to?(:decode_event)
      encode_event = encoder_name if formatter.respond_to?(:encode_event)
      decode_data = formatter.respond_to?(:decode_data)
      encode_data = formatter.respond_to?(:encode_data)
      register_formatter_methods(formatter,
                                 decode_event: decode_event,
                                 encode_event: encode_event,
                                 decode_data: decode_data,
                                 encode_data: encode_data)
      self
    end

    ##
    # Registers the given formatter for the given operations. Some arguments
    # are activated by passing `true`, whereas those that rely on a format
    # name are activated by passing in a name string.
    #
    # @param formatter [Object] The formatter.
    # @param decode_event [boolean] If true, register the formatter's
    #     {CloudEvents::Format#decode_event} method.
    # @param encode_event [String] If set to a string, use the formatter's
    #     {CloudEvents::Format#encode_event} method when that name is
    #     requested.
    # @param decode_data [boolean] If true, register the formatter's
    #     {CloudEvents::Format#decode_data} method.
    # @param encode_data [boolean] If true, register the formatter's
    #     {CloudEvents::Format#encode_data} method.
    # @return [self]
    #
    def register_formatter_methods(formatter,
                                   decode_event: false,
                                   encode_event: nil,
                                   decode_data: false,
                                   encode_data: false)
      @event_decoders.formats.unshift(formatter) if decode_event
      if encode_event
        encoders = @event_encoders[encode_event] ||= Format::Multi.new do |result|
          result&.key?(:content) && result.key?(:content_type) ? result : nil
        end
        encoders.formats.unshift(formatter)
      end
      @data_decoders.formats.unshift(formatter) if decode_data
      @data_encoders.formats.unshift(formatter) if encode_data
      self
    end

    ##
    # The name of the encoder to use if none is specified.
    #
    # @return [String,nil]
    #
    attr_accessor :default_encoder_name

    ##
    # Determine whether a Kafka message is likely a CloudEvent, by
    # inspecting headers only (does not parse the value).
    #
    # @param message [Hash] The Kafka message hash.
    # @return [boolean]
    #
    def probable_event?(message)
      headers = message[:headers] || {}
      return true if headers.key?("ce_specversion")
      content_type_string = headers["content-type"]
      return false unless content_type_string
      content_type = ContentType.new(content_type_string)
      content_type.media_type == "application" && content_type.subtype_base == "cloudevents"
    end

    ##
    # Decode an event from a Kafka message hash.
    #
    # @param message [Hash] A hash with `:key`, `:value`, and `:headers` keys.
    # @param allow_opaque [boolean] If true, returns {Event::Opaque} for
    #     unrecognized structured formats. Default is false.
    # @param reverse_key_mapper [Proc,nil,:NOT_SET] A callable
    #     `(key) -> Hash`, or `nil` to skip key mapping. Defaults to the
    #     instance's reverse_key_mapper.
    # @param format_args [keywords] Extra args forwarded to formatters.
    # @return [CloudEvents::Event] The decoded event.
    # @raise [NotCloudEventError] if the message is not a CloudEvent.
    # @raise [SpecVersionError] if the specversion is not supported.
    # @raise [UnsupportedFormatError] if a structured format is not recognized.
    # @raise [FormatSyntaxError] if the structured content is malformed.
    #
    def decode_event(message, allow_opaque: false, reverse_key_mapper: :NOT_SET, **format_args)
      reverse_key_mapper = @reverse_key_mapper if reverse_key_mapper == :NOT_SET
      headers = message[:headers] || {}
      content_type_string = headers["content-type"]
      content_type = ContentType.new(content_type_string) if content_type_string

      event = decode_content(message, headers, content_type, content_type_string, allow_opaque, **format_args)
      apply_reverse_key_mapper(event, message[:key], reverse_key_mapper)
    end

    ##
    # Encode an event into a Kafka message hash.
    #
    # @param event [CloudEvents::Event,CloudEvents::Event::Opaque] The event.
    # @param structured_format [boolean,String] If false (default), encodes
    #     in binary content mode. If true or a format name string, encodes
    #     in structured content mode.
    # @param key_mapper [Proc,nil,:NOT_SET] A callable
    #     `(event) -> String|nil`, or `nil` to always produce a `nil` key.
    #     Defaults to the instance's key_mapper.
    # @param format_args [keywords] Extra args forwarded to formatters.
    # @return [Hash] A hash with `:key`, `:value`, and `:headers` keys.
    #
    def encode_event(event, structured_format: false, key_mapper: :NOT_SET, **format_args)
      key_mapper = @key_mapper if key_mapper == :NOT_SET
      if event.is_a?(Event::Opaque)
        return encode_opaque_event(event)
      end
      if structured_format
        encode_structured_event(event, structured_format, key_mapper, **format_args)
      else
        encode_binary_event(event, key_mapper, **format_args)
      end
    end

    # @private
    OMIT_ATTR_NAMES = ["specversion", "spec_version", "data", "datacontenttype", "data_content_type"].freeze

    private

    # Detect content mode, reject batches, and dispatch to the appropriate
    # binary or structured decoder. Raises if the message is not a CloudEvent.
    def decode_content(message, headers, content_type, content_type_string, allow_opaque, **format_args)
      if content_type&.media_type == "application" && content_type.subtype_base == "cloudevents-batch"
        raise(BatchNotSupportedError, "Kafka protocol binding does not support batch content mode")
      end
      if content_type&.media_type == "application" && content_type.subtype_base == "cloudevents"
        return decode_structured_content(message, content_type, allow_opaque, **format_args)
      end
      if headers.key?("ce_specversion")
        return decode_binary_content(message, content_type, **format_args)
      end
      ct_desc = content_type_string ? content_type_string.inspect : "not present"
      raise(NotCloudEventError, "content-type is #{ct_desc}, and ce_specversion header is not present")
    end

    # Decode a single event from binary content mode. Reads ce_* headers as
    # attributes and the message value as event data.
    def decode_binary_content(message, content_type, **format_args)
      headers = message[:headers] || {}
      spec_version = headers["ce_specversion"]
      raise(SpecVersionError, "Unrecognized specversion: #{spec_version}") unless spec_version =~ /^1(\.|$)/
      attributes = { "spec_version" => spec_version }
      headers.each do |key, value|
        next unless key.start_with?("ce_")
        attr_name = key[3..].downcase
        attributes[attr_name] = value unless OMIT_ATTR_NAMES.include?(attr_name)
      end
      value = message[:value]
      unless value.nil?
        content_type = populate_data_attributes(attributes, value, content_type, spec_version, format_args)
      end
      attributes["data_content_type"] = content_type if content_type
      Event.create(spec_version: spec_version, set_attributes: attributes)
    end

    # Populate data-related attributes (data_encoded, data, data_content_type)
    # by running the value through registered data decoders. Returns the
    # (possibly updated) content_type.
    def populate_data_attributes(attributes, value, content_type, spec_version, format_args)
      attributes["data_encoded"] = value
      result = @data_decoders.decode_data(spec_version: spec_version,
                                          content: value,
                                          content_type: content_type,
                                          **format_args)
      if result
        attributes["data"] = result[:data]
        content_type = result[:content_type]
      end
      content_type
    end

    # Decode a single event from structured content mode. Delegates to
    # registered event decoders, falling back to Event::Opaque if allowed.
    def decode_structured_content(message, content_type, allow_opaque, **format_args)
      content = message[:value].to_s
      result = @event_decoders.decode_event(content: content,
                                            content_type: content_type,
                                            data_decoder: @data_decoders,
                                            **format_args)
      if result
        event = result[:event]
        if event && !event.spec_version.start_with?("1")
          raise(SpecVersionError, "Unrecognized specversion: #{event.spec_version}")
        end
        return event
      end
      return Event::Opaque.new(content, content_type) if allow_opaque
      raise(UnsupportedFormatError, "Unknown cloudevents content type: #{content_type}")
    end

    # Apply the reverse_key_mapper to merge Kafka record key attributes into
    # the decoded event. Returns the event unchanged if the mapper is nil or
    # returns an empty hash.
    def apply_reverse_key_mapper(event, key, reverse_key_mapper)
      return event unless reverse_key_mapper
      mapped_attrs = reverse_key_mapper.call(key)
      return event if mapped_attrs.nil? || mapped_attrs.empty?
      event.with(**mapped_attrs.transform_keys(&:to_sym))
    end

    # Encode an event in binary content mode. Writes attributes as ce_*
    # headers and event data as the message value.
    def encode_binary_event(event, key_mapper, **format_args)
      key = key_mapper&.call(event)
      headers = {}
      event.to_h.each do |attr_key, value|
        next if ["data", "data_encoded", "datacontenttype"].include?(attr_key)
        headers["ce_#{attr_key}"] = value.to_s
      end
      body, content_type = extract_event_data(event, format_args)
      headers["content-type"] = content_type.to_s if content_type
      { key: key, value: body, headers: headers }
    end

    # Encode an event in structured content mode using a named format encoder.
    # The entire event is serialized into the message value.
    def encode_structured_event(event, structured_format, key_mapper, **format_args)
      key = key_mapper&.call(event)
      structured_format = default_encoder_name if structured_format == true
      raise(::ArgumentError, "Format name not specified, and no default is set") unless structured_format
      result = @event_encoders[structured_format]&.encode_event(event: event,
                                                                data_encoder: @data_encoders,
                                                                **format_args)
      raise(::ArgumentError, "Unknown format name: #{structured_format.inspect}") unless result
      { key: key, value: result[:content], headers: { "content-type" => result[:content_type].to_s } }
    end

    # Encode an opaque event by passing through its content and content_type
    # directly, with a nil key.
    def encode_opaque_event(event)
      { key: nil, value: event.content, headers: { "content-type" => event.content_type.to_s } }
    end

    # Extract the event data and content type for binary mode encoding.
    # Uses data_encoded if present, otherwise delegates to data encoders.
    # Returns [body, content_type], where body is nil for tombstones.
    def extract_event_data(event, format_args)
      body = event.data_encoded
      if body
        [body, event.data_content_type]
      elsif event.data?
        result = @data_encoders.encode_data(spec_version: event.spec_version,
                                            data: event.data,
                                            content_type: event.data_content_type,
                                            **format_args)
        raise(UnsupportedFormatError, "Could not encode data content-type") unless result
        [result[:content], result[:content_type]]
      else
        [nil, nil]
      end
    end
  end
end
