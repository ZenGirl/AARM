module Rack
  module AARM
    module DSL
      class RoleRight
        attr_accessor :verbs, :on_resources

        def initialize(verbs, resources)
          @verbs, @on_resources = verbs, resources
        end
      end
    end
  end
end

