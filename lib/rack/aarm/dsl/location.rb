module Rack
  module AARM
    module DSL
      class Location
        attr_accessor :ipv4, :active_ranges

        def initialize(ipv4)
          @ipv4 = ipv4
          @active_ranges = []
        end

        def add_active_range(active_range)
          @active_ranges << active_range
          self
        end
      end
    end
  end
end

