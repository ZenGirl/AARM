module Rack
  module AARM
    module DSL
      class VendorKey
        attr_accessor :active_range, :key, :secret

        def initialize(active_range, key, secret)
          @active_range, @key, @secret = active_range, key, secret
        end
      end
    end
  end
end

