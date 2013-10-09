module Rack
  module AARM
    module DSL
      class Verb
        attr_accessor :name, :active_ranges

        def initialize(verb)
          @name = verb
          @active_ranges = []
        end

        def add_active_range(active_range)
          active_ranges << active_range
          self
        end

        def add_binding(caller)
          @caller = caller
        end

        def back_to_suffix
          @caller
        end
      end
    end
  end
end
