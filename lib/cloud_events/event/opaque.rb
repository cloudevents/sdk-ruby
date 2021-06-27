# frozen_string_literal: true

module CloudEvents
  module Event
    ##
    # This object represents opaque event data that arrived in structured
    # content mode but was not in a recognized format. It may represent a
    # single event or a batch of events.
    #
    # The event data is retained in a form that can be reserialized (in a
    # structured cotent mode in the same format) but cannot otherwise be
    # inspected.
    #
    # This object is immutable, and Ractor-shareable on Ruby 3.
    #
    class Opaque
      ##
      # Create an opaque object wrapping the given content and a content type.
      #
      # @param content [String] The opaque serialized event data.
      # @param content_type [CloudEvents::ContentType,nil] The content type,
      #     or `nil` if there is no content type.
      # @param batch [boolean] Whether this represents a batch. If set to `nil`
      #     or not provided, the value will be inferred from the content type
      #     if possible, or otherwise set to `nil` indicating not known.
      #
      def initialize content, content_type, batch: nil
        @content = content.freeze
        @content_type = content_type
        if batch.nil? && content_type&.media_type == "application"
          case content_type.subtype_base
          when "cloudevents"
            batch = false
          when "cloudevents-batch"
            batch = true
          end
        end
        @batch = batch
        freeze
      end

      ##
      # The opaque serialized event data
      #
      # @return [String]
      #
      attr_reader :content

      ##
      # The content type, or `nil` if there is no content type.
      #
      # @return [CloudEvents::ContentType,nil]
      #
      attr_reader :content_type

      ##
      # Whether this represents a batch, or `nil` if not known.
      #
      # @return [boolean,nil]
      #
      def batch?
        @batch
      end

      ## @private
      def == other
        Opaque === other &&
          @content == other.content &&
          @content_type == other.content_type &&
          @batch == other.batch?
      end
      alias eql? ==

      ## @private
      def hash
        @content.hash ^ @content_type.hash ^ @batch.hash
      end
    end
  end
end
