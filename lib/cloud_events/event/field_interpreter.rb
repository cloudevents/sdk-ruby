# frozen_string_literal: true

module CloudEvents
  module Event
    ##
    # A helper that extracts and interprets event fields from an input hash.
    #
    # @private
    #
    class FieldInterpreter
      def initialize args
        @args = keys_to_strings args
        @attributes = {}
      end

      def finish_attributes
        @args.each do |key, value|
          @attributes[key.freeze] = value.to_s.freeze unless value.nil?
        end
        @args = {}
        @attributes.freeze
      end

      def string keys, required: false
        object keys, required: required do |value|
          case value
          when ::String
            raise AttributeError, "The #{keys.first} field cannot be empty" if value.empty?
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
              [::URI.parse(value), value]
            rescue ::URI::InvalidURIError => e
              raise AttributeError, "Illegal format for #{keys.first}: #{e.message}"
            end
          when ::URI::Generic
            [value, value.to_s]
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
              [::DateTime.rfc3339(value), value]
            rescue ::Date::Error => e
              raise AttributeError, "Illegal format for #{keys.first}: #{e.message}"
            end
          when ::DateTime
            [value, value.rfc3339]
          when ::Time
            value = value.to_datetime
            [value, value.rfc3339]
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
            [ContentType.new(value), value]
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
            [value, value]
          else
            raise AttributeError, "Illegal type for #{keys.first}:" \
                                  " String expected but #{value.class} found"
          end
        end
      end

      UNDEFINED = ::Object.new.freeze

      def object keys, required: false, allow_nil: false
        value = UNDEFINED
        keys.each do |key|
          key_present = @args.key? key
          val = @args.delete key
          value = val if allow_nil && key_present || !allow_nil && !val.nil?
        end
        if value == UNDEFINED
          raise AttributeError, "The #{keys.first} field is required" if required
          return nil
        end
        if block_given?
          converted, raw = yield value
          deep_freeze converted
        else
          converted = raw = value
        end
        @attributes[keys.first.freeze] = raw.freeze
        converted
      end

      private

      def deep_freeze obj
        case obj
        when ::Hash
          obj.each do |key, val|
            deep_freeze key
            deep_freeze val
          end
        when ::Array
          obj.each do |val|
            deep_freeze val
          end
        else
          obj.instance_variables.each do |iv|
            deep_freeze obj.instance_variable_get iv
          end
        end
        obj.freeze
      end

      def keys_to_strings hash
        result = {}
        hash.each do |key, val|
          result[key.to_s] = val
        end
        result
      end
    end
  end
end
