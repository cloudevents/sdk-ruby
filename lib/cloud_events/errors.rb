# frozen_string_literal: true

module CloudEvents
  ##
  # Base class for all CloudEvents errors.
  #
  class CloudEventsError < ::StandardError
  end

  ##
  # An error signaling that a protocol handler does not believe that a piece of
  # data is intended to be a CloudEvent.
  #
  class NotCloudEventError < ::StandardError
  end

  ##
  # Errors indicating unsupported or incorrectly formatted HTTP content or
  # headers.
  #
  class HttpContentError < CloudEventsError
  end

  ##
  # Errors indicating an unsupported or incorrect spec version.
  #
  class SpecVersionError < CloudEventsError
  end

  ##
  # Errors related to CloudEvent attributes.
  #
  class AttributeError < CloudEventsError
  end
end
