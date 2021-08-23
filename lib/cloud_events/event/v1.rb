# frozen_string_literal: true

require "date"
require "uri"

require "cloud_events/event/field_interpreter"
require "cloud_events/event/utils"

module CloudEvents
  module Event
    ##
    # A CloudEvents V1 data type.
    #
    # This object represents a complete CloudEvent, including the event data
    # and context attributes. It supports the standard required and optional
    # attributes defined in CloudEvents V1.0, and arbitrary extension
    # attributes.
    #
    # Values for most attributes can be obtained in their encoded string form
    # via the {Event::V1#[]} method. Additionally, standard attributes have
    # their own accessor methods that may return decoded Ruby objects (such as
    # a `DateTime` object for the `time` attribute).
    #
    # The `data` attribute is treated specially because it is subject to
    # arbitrary encoding governed by the `datacontenttype` attribute. Data is
    # expressed in two related fields: {Event::V1#data} and
    # {Event::V1#data_encoded}. The former, `data`, _may_ be an arbitrary Ruby
    # object representing the decoded form of the data (for example, a Hash for
    # most JSON-formatted data.) The latter, `data_encoded`, _must_, if
    # present, be a Ruby String object representing the encoded string or
    # byte array form of the data.
    #
    # When the CloudEvents Ruby SDK encodes an event for transmission, it will
    # use the `data_encoded` field if present. Otherwise, it will attempt to
    # encode the `data` field using any available encoder that recognizes the
    # content-type. Currently, text and JSON types are supported. If the type
    # is not supported, event encoding may fail. It is thus recommended that
    # applications provide a `data_encoded` string, if the `data` object is
    # nontrivially encoded.
    #
    # This object is immutable, and Ractor-shareable on Ruby 3. The data and
    # attribute values can be retrieved but not modified. To obtain an event
    # with modifications, use the {#with} method to create a copy with the
    # desired changes.
    #
    # See https://github.com/cloudevents/spec/blob/v1.0/spec.md for
    # descriptions of the standard attributes.
    #
    class V1
      include Event

      ##
      # Create a new cloud event object with the given data and attributes.
      #
      # ### Specifying event attributes
      #
      # Event attributes may be presented as keyword arguments, or as a Hash
      # passed in via the special `:set_attributes` keyword argument (but not
      # both). The `:set_attributes` keyword argument is useful for passing in
      # attributes whose keys are strings rather than symbols, which some
      # versions of Ruby will not accept as keyword arguments.
      #
      # The following standard attributes are supported and exposed as
      # attribute methods on the object.
      #
      #  *  **:spec_version** (or **:specversion**) [`String`] - _required_ -
      #     The CloudEvents spec version (i.e. the `specversion` field.)
      #  *  **:id** [`String`] - _required_ - The event `id` field.
      #  *  **:source** [`String`, `URI`] - _required_ - The event `source`
      #     field.
      #  *  **:type** [`String`] - _required_ - The event `type` field.
      #  *  **:data** [`Object`] - _optional_ - The "decoded" Ruby object form
      #     of the event `data` field, if known. (e.g. a Hash representing a
      #     JSON document)
      #  *  **:data_encoded** [`String`] - _optional_ - The "encoded" string
      #     form of the event `data` field, if known. This should be set along
      #     with the `data_content_type`.
      #  *  **:data_content_type** (or **:datacontenttype**) [`String`,
      #     {ContentType}] - _optional_ - The content-type for the encoded data
      #     (i.e. the event `datacontenttype` field.)
      #  *  **:data_schema** (or **:dataschema**) [`String`, `URI`] -
      #     _optional_ - The event `dataschema` field.
      #  *  **:subject** [`String`] - _optional_ - The event `subject` field.
      #  *  **:time** [`String`, `DateTime`, `Time`] - _optional_ - The
      #     event `time` field.
      #
      # Any additional attributes are assumed to be extension attributes.
      # They are not available as separate methods, but can be accessed via
      # the {Event::V1#[]} operator.
      #
      # Note that attribute objects passed in may get deep-frozen if they are
      # used in the final event object. This is particularly important for the
      # `:data` field, for example if you pass a structured hash. If this is an
      # issue, make a deep copy of objects before passing to this constructor.
      #
      # ### Specifying payload data
      #
      # Typically you should provide _both_ the `:data` and `:data_encoded`
      # fields, the former representing the decoded (Ruby object) form of the
      # data, and the second providing a hint to formatters and protocol
      # bindings for how to seralize the data. In this case, the {#data} and
      # {#data_encoded} methods will return the corresponding values, and
      # {#data_decoded?} will return true to indicate that {#data} represents
      # the decoded form.
      #
      # If you provide _only_ the `:data` field, omitting `:data_encoded`, then
      # the value is expected to represent the decoded (Ruby object) form of
      # the data. The {#data} method will return this decoded value, and
      # {#data_decoded?} will return true. The {#data_encoded} method will
      # return nil.
      # When serializing such an event, it will be up to the formatter or
      # protocol binding to encode the data. This means serialization _could_
      # fail if the formatter does not understand the data's content type.
      # Omitting `:data_encoded` is common if the content type is JSON related
      # (e.g. `application/json`) and the event is being encoded in JSON
      # structured format, because the data encoding is trivial. This form can
      # also be used when the content type is `text/*`, for which encoding is
      # also trivial.
      #
      # If you provide _only_ the `:data_encoded` field, omitting `:data`, then
      # the value is expected to represent the encoded (string) form of the
      # data. The {#data_encoded} method will return this value. Additionally,
      # the {#data} method will return the same _encoded_ value, and
      # {#data_decoded?} will return false.
      # Event objects of this form may be returned from a protocol binding when
      # it decodes an event with a `datacontenttype` that it does not know how
      # to interpret. Applications should query {#data_decoded?} to determine
      # whether the {#data} method returns encoded or decoded data.
      #
      # If you provide _neither_ `:data` nor `:data_encoded`, the event will
      # have no payload data. Both {#data} and {#data_encoded} will return nil,
      # and {#data_decoded?} will return false. (Additionally, {#data?} will
      # return false to signal the absence of any data.)
      #
      # @param set_attributes [Hash] The data and attributes, as a hash.
      #     (Also available using the deprecated keyword `attributes`.)
      # @param args [keywords] The data and attributes, as keyword arguments.
      #
      def initialize set_attributes: nil, attributes: nil, **args
        interpreter = FieldInterpreter.new set_attributes || attributes || args
        @spec_version = interpreter.spec_version ["specversion", "spec_version"], accept: /^1(\.|$)/
        @id = interpreter.string ["id"], required: true
        @source = interpreter.uri ["source"], required: true
        @type = interpreter.string ["type"], required: true
        @data_encoded = interpreter.string ["data_encoded"], allow_empty: true
        @data = interpreter.data_object ["data"]
        if @data == FieldInterpreter::UNDEFINED
          @data = @data_encoded
          @data_decoded = false
        else
          @data_decoded = true
        end
        @data_content_type = interpreter.content_type ["datacontenttype", "data_content_type"]
        @data_schema = interpreter.uri ["dataschema", "data_schema"]
        @subject = interpreter.string ["subject"]
        @time = interpreter.rfc3339_date_time ["time"]
        @attributes = interpreter.finish_attributes
        freeze
      end

      ##
      # Create and return a copy of this event with the given changes. See
      # the constructor for the parameters that can be passed. In general,
      # you can pass a new value for any attribute, or pass `nil` to remove
      # an optional attribute.
      #
      # @param changes [keywords] See {#initialize} for a list of arguments.
      # @return [FunctionFramework::CloudEvents::Event]
      #
      def with **changes
        changes = Utils.keys_to_strings changes
        attributes = @attributes.dup
        if changes.key?("data") || changes.key?("data_encoded")
          attributes.delete "data"
          attributes.delete "data_encoded"
        end
        attributes.merge! changes
        V1.new set_attributes: attributes
      end

      ##
      # Return the value of the given named attribute. Both standard and
      # extension attributes are supported.
      #
      # Attribute names must be given as defined in the standard CloudEvents
      # specification. For example `specversion` rather than `spec_version`.
      #
      # Results are given in their "raw" form, generally a string. This may
      # be different from the Ruby object returned from corresponding
      # attribute methods. For example:
      #
      #     event["time"]     # => String rfc3339 representation
      #     event.time        # => DateTime object
      #
      # Results are also always frozen and cannot be modified in place.
      #
      # @param key [String,Symbol] The attribute name.
      # @return [String,nil]
      #
      def [] key
        @attributes[key.to_s]
      end

      ##
      # Return a hash representation of this event. The returned hash is an
      # unfrozen deep copy. Modifications do not affect the original event.
      #
      # @return [Hash]
      #
      def to_h
        Utils.deep_dup @attributes
      end

      ##
      # The `id` field. Required.
      #
      # @return [String]
      #
      attr_reader :id

      ##
      # The `source` field as a `URI` object. Required.
      #
      # @return [URI]
      #
      attr_reader :source

      ##
      # The `type` field. Required.
      #
      # @return [String]
      #
      attr_reader :type

      ##
      # The `specversion` field. Required.
      #
      # @return [String]
      #
      attr_reader :spec_version
      alias specversion spec_version

      ##
      # The event `data` field, or `nil` if there is no data.
      #
      # This may return the data as an encoded string _or_ as a decoded Ruby
      # object. The {#data_decoded?} method specifies whether the `data` value
      # is decoded or encoded.
      #
      # In most cases, {#data} returns a decoded value, unless the event was
      # received from a source that could not decode the content. For example,
      # most protocol bindings understand how to decode JSON, so an event
      # received with a {#data_content_type} of `application/json` will usually
      # return a decoded object (usually a Hash) from {#data}.
      #
      # See also {#data_encoded} and {#data_decoded?}.
      #
      # @return [Object] if containing decoded data
      # @return [String] if containing encoded data
      # @return [nil] if there is no data
      #
      attr_reader :data

      ##
      # The encoded string representation of the data, i.e. its raw form used
      # when encoding an event for transmission. This may be `nil` if there is
      # no data, or if the encoded form is not known.
      #
      # See also {#data}.
      #
      # @return [String,nil]
      #
      attr_reader :data_encoded

      ##
      # Indicates whether the {#data} field returns decoded data.
      #
      # @return [true] if {#data} returns a decoded Ruby object
      # @return [false] if {#data} returns an encoded string or if the event
      #     has no data.
      #
      def data_decoded?
        @data_decoded
      end

      ##
      # Indicates whether the data field is present. If there is no data,
      # {#data} will return `nil`, and {#data_decoded?} will return false.
      #
      # Generally, if there is no data, the {#data_content_type} field should
      # also be absent, but this is not enforced.
      #
      # @return [boolean]
      #
      def data?
        !@data.nil? || @data_decoded
      end

      ##
      # The optional `datacontenttype` field as a {CloudEvents::ContentType}
      # object, or `nil` if the field is absent.
      #
      # @return [CloudEvents::ContentType,nil]
      #
      attr_reader :data_content_type
      alias datacontenttype data_content_type

      ##
      # The optional `dataschema` field as a `URI` object, or `nil` if the
      # field is absent.
      #
      # @return [URI,nil]
      #
      attr_reader :data_schema
      alias dataschema data_schema

      ##
      # The optional `subject` field, or `nil` if the field is absent.
      #
      # @return [String,nil]
      #
      attr_reader :subject

      ##
      # The optional `time` field as a `DateTime` object, or `nil` if the
      # field is absent.
      #
      # @return [DateTime,nil]
      #
      attr_reader :time

      ## @private
      def == other
        other.is_a?(V1) && @attributes == other.instance_variable_get(:@attributes)
      end
      alias eql? ==

      ## @private
      def hash
        @attributes.hash
      end
    end
  end
end
