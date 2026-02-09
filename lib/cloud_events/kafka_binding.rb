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
  end
end
