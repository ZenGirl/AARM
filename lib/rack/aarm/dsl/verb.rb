module Rack
  module AARM
    module DSL
      class Verb
        attr_accessor :name, :active_ranges

        # -------------------------------------------------------------------
        # Need the helpers
        # -------------------------------------------------------------------
        require_relative 'helpers'
        include Rack::AARM::DSL::Helpers

        # -------------------------------------------------------------------
        # Creates a new verb
        # -------------------------------------------------------------------
        def initialize(verb)
          raise ArgumentError.new(Rack::AARM::DSL::Helpers::ARGUMENTS_BAD) unless verb.is_a? String
          raise ArgumentError.new(Rack::AARM::DSL::Helpers::ARGUMENTS_BAD) unless %w(GET POST PUT DELETE HEAD).include? verb
          @name = verb
          @active_ranges = []
        end

        # -------------------------------------------------------------------
        # Add an active range
        # -------------------------------------------------------------------
        def add_active_range(active_range)
          raise ArgumentError.new(Rack::AARM::DSL::Helpers::ARGUMENTS_BAD) unless active_range.is_a? Rack::AARM::DSL::ActiveRange
          active_ranges << active_range
          self
        end

        # -------------------------------------------------------------------
        # Test active on
        # -------------------------------------------------------------------
        def active_on?(date)
          d = prepare_date(date, Rack::AARM::DSL::Helpers::INCOMING_DATE_ERROR)
          @active_ranges.any? { |active_range| active_range.in_range? d }
        end

        # -------------------------------------------------------------------
        # Used purely to get back to vendor caller instance
        # -------------------------------------------------------------------
        def add_binding(caller)
          @caller = caller
        end

        # -------------------------------------------------------------------
        # As above
        # -------------------------------------------------------------------
        def back_to_suffix
          @caller
        end
      end
    end
  end
end
