module Rack # :nodoc: so we don't have an empty doc page for the namespace
  module AARM # :nodoc:
    module DSL # :nodoc:

      # ---------------------------------------------------------------------
      # Describes a standardised datetime range
      # ---------------------------------------------------------------------
      class ActiveRange
        attr_accessor :from_date, :to_date

        # -------------------------------------------------------------------
        # Need the helpers
        # -------------------------------------------------------------------
        require_relative 'helpers'
        include Rack::AARM::DSL::Helpers

        # -------------------------------------------------------------------
        # Creates a new ActiveRange based on +from_date+ and +to_date+
        # +from_date+ and +to_date+ must either be DateTime objects or parseable date strings
        #
        # <i>Exceptions</i>
        #   Will raise +ArgumentError+ if not a DateTime or parseable string or +from_date+ later than +to_date+
        # -------------------------------------------------------------------
        def initialize(from_date, to_date)
          f_d = prepare_date(from_date, Rack::AARM::DSL::Helpers::FROM_DATE_ERROR)
          t_d = prepare_date(to_date, Rack::AARM::DSL::Helpers::TO_DATE_ERROR)
          raise ArgumentError.new(Rack::AARM::DSL::Helpers::ORDER_ERROR) if t_d < f_d
          @from_date, @to_date = f_d, t_d
        end

        # -------------------------------------------------------------------
        # Returns a new +ActiveRange+ instance based on EPOCH to 2100
        # -------------------------------------------------------------------
        def self.for_all_time
          new(all_past, all_future)
        end

        # -------------------------------------------------------------------
        # EPOCH
        # -------------------------------------------------------------------
        def self.all_past
          DateTime.new(1970, 1, 1)
        end

        # -------------------------------------------------------------------
        # Set to 2100-01-01
        # -------------------------------------------------------------------
        def self.all_future
          DateTime.new(2100, 1, 1)
        end

        # -------------------------------------------------------------------
        # Checks an incoming date is between a range (inclusive)
        #
        # NOTE:
        # You can't use the '===' construct as ranges only support Dates,
        # Not DateAndTimes.
        #
        # +date+ a +DateTime+ or DateTime parseable String
        # -------------------------------------------------------------------
        def in_range?(date)
          # Can't use ranges for date and time, only date
          # range = @from_date..@to_date
          # range === date # This doesn't work as expected
          d = prepare_date(date, Rack::AARM::DSL::Helpers::INCOMING_DATE_ERROR)
          d >= @from_date and d <= @to_date
        end

        # -------------------------------------------------------------------
        # Override == to avoid comparison issues
        # -------------------------------------------------------------------
        def ==(other)
          other.from_date == @from_date and other.to_date == @to_date
        end

      end
    end
  end
end