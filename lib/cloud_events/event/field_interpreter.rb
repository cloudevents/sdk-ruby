# frozen_string_literal: true

require "cloud_events/event/utils"

module CloudEvents
  module Event
    ##
    # A helper that extracts and interprets event fields from an input hash.
    # @private
    #
    class FieldInterpreter
      def initialize args
        @args = Utils.keys_to_strings args
        @attributes = {}
      end

      def finish_attributes
        @args.each do |key, value|
          @attributes[key.freeze] = value.to_s.freeze unless value.nil?
        end
        @args = {}
        @attributes.freeze
      end

      def string keys, required: false, allow_empty: false
        object keys, required: required do |value|
          case value
          when ::String
            raise AttributeError, "The #{keys.first} field cannot be empty" if value.empty? && !allow_empty
            value.freeze
            [value, value]
          else
            raise AttributeError, "Illegal type for #{keys.first}:" \
                                  " String expected but #{value.class} found"
          end
        end
      end

      def uri keys, required: false
        object keys, required: required do |value|
          case value
          when ::String
            raise AttributeError, "The #{keys.first} field cannot be empty" if value.empty?
            begin
              [Utils.deep_freeze(::URI.parse(value)), value.freeze]
            rescue ::URI::InvalidURIError => e
              raise AttributeError, "Illegal format for #{keys.first}: #{e.message}"
            end
          when ::URI::Generic
            [Utils.deep_freeze(value), value.to_s.freeze]
          else
            raise AttributeError, "Illegal type for #{keys.first}:" \
                                  " String or URI expected but #{value.class} found"
          end
        end
      end

      def rfc3339_date_time keys, required: false
        object keys, required: required do |value|
          case value
          when ::String
            begin
              [Utils.deep_freeze(::DateTime.rfc3339(value)), value.freeze]
            rescue ::Date::Error => e
              raise AttributeError, "Illegal format for #{keys.first}: #{e.message}"
            end
          when ::DateTime
            [Utils.deep_freeze(value), value.rfc3339.freeze]
          when ::Time
            value = value.to_datetime
            [Utils.deep_freeze(value), value.rfc3339.freeze]
          else
            raise AttributeError, "Illegal type for #{keys.first}:" \
                                  " String, Time, or DateTime expected but #{value.class} found"
          end
        end
      end

      def content_type keys, required: false
        object keys, required: required do |value|
          case value
          when ::String
            raise AttributeError, "The #{keys.first} field cannot be empty" if value.empty?
            [ContentType.new(value), value.freeze]
          when ContentType
            [value, value.to_s]
          else
            raise AttributeError, "Illegal type for #{keys.first}:" \
                                  " String, or ContentType expected but #{value.class} found"
          end
        end
      end

      def spec_version keys, accept:
        object keys, required: true do |value|
          case value
          when ::String
            raise SpecVersionError, "Unrecognized specversion: #{value}" unless accept =~ value
            value.freeze
            [value, value]
          else
            raise AttributeError, "Illegal type for #{keys.first}:" \
                                  " String expected but #{value.class} found"
          end
        end
      end

      def data_object keys, required: false
        object keys, required: required, allow_nil: true do |value|
          Utils.deep_freeze value
          [value, value]
        end
      end

      UNDEFINED = ::Object.new.freeze

      private

      def object keys, required: false, allow_nil: false
        value = UNDEFINED
        keys.each do |key|
          key_present = @args.key? key
          val = @args.delete key
          value = val if allow_nil && key_present || !allow_nil && !val.nil?
        end
        if value == UNDEFINED
          raise AttributeError, "The #{keys.first} field is required" if required
          return allow_nil ? UNDEFINED : nil
        end
        converted, raw = yield value
        @attributes[keys.first.freeze] = raw
        converted
      end
    end
  end
end
