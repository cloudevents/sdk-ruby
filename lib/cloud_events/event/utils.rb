# frozen_string_literal: true

module CloudEvents
  module Event
    ##
    # A variety of helper methods.
    # @private
    #
    module Utils
      class << self
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

        def deep_dup obj
          case obj
          when ::Hash
            obj.each_with_object({}) { |(key, val), hash| hash[deep_dup key] = deep_dup val }
          when ::Array
            obj.map { |val| deep_dup val }
          else
            obj.dup
          end
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
end
