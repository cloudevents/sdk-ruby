# frozen_string_literal: true

require "cloud_events/content_type"
require "cloud_events/errors"
require "cloud_events/event"
require "cloud_events/format"
require "cloud_events/http_binding"
require "cloud_events/json_format"
require "cloud_events/text_format"

##
# CloudEvents implementation.
#
# This is a Ruby implementation of the [CloudEvents](https://cloudevents.io)
# specification. It supports both
# [CloudEvents 0.3](https://github.com/cloudevents/spec/blob/v0.3/spec.md) and
# [CloudEvents 1.0](https://github.com/cloudevents/spec/blob/v1.0/spec.md).
#
module CloudEvents
  # @private
  SUPPORTED_SPEC_VERSIONS = ["0.3", "1.0"].freeze

  class << self
    ##
    # The spec versions supported by this implementation.
    #
    # @return [Array<String>]
    #
    def supported_spec_versions
      SUPPORTED_SPEC_VERSIONS
    end
  end
end
