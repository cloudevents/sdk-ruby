# frozen_string_literal: true

require 'cucumber/core/test/result'
require 'cucumber/core/test/actions/action'

module Cucumber
  module Core
    module Test
      class UnskippableAction < Action
        def skip(*args)
          execute(*args)
        end
      end
    end
  end
end
