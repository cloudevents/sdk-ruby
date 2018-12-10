module Cloudevents
  module V01
    class HTTPMarshaller
      def initialize(converters = [])
        @converters = converters
      end

      def self.default
        new([
          BinaryConverter.new,
          JSONConverter.new,
        ])
      end

      def from_request(request)
        raise ArgumentError, "request can not be nil" if request.nil?

        converter = @converters.find do |converter|
          converter.can_read?(request.media_type)
        end

        if converter
          converter.read(Event.new, request) { |io| io.read }
        else
          raise ContentTypeNotSupportedError
        end
      end
    end
  end
end
