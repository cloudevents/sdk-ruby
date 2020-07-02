# frozen_string_literal: true

module CloudEvents
  ##
  # Base class for all CloudEvents errors.
  #
  class CloudEventsError < ::StandardError
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
