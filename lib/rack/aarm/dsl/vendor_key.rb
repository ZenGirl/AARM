module Rack
  module AARM
    module DSL
      class VendorKey
        attr_accessor :active_range, :key, :secret

        # -------------------------------------------------------------------
        # Need the helpers
        # -------------------------------------------------------------------
        require_relative 'helpers'
        include Rack::AARM::DSL::Helpers

        def initialize(active_range, key, secret)
          raise ArgumentError.new(Rack::AARM::DSL::Helpers::ARGUMENTS_BAD) unless active_range.is_a? Rack::AARM::DSL::ActiveRange
          raise ArgumentError.new(Rack::AARM::DSL::Helpers::ARGUMENTS_BAD) unless key.is_a? String and key.strip.size > 0
          raise ArgumentError.new(Rack::AARM::DSL::Helpers::ARGUMENTS_BAD) unless secret.is_a? String and secret.strip.size > 0
          @active_range, @key, @secret = active_range, key, secret
        end
      end
    end
  end
end

