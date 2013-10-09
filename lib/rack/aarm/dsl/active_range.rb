module Rack
  module AARM
    module DSL
      class ActiveRange
        attr_accessor :from_date, :to_date

        FROM_DATE_ERROR = 'FromDate must be a DateTime or String in the format "YYYY-MM-DD" or "YYYY-MM-DD hh:mm:ss"'
        TO_DATE_ERROR = 'ToDate must be a DateTime or String in the format "YYYY-MM-DD" or "YYYY-MM-DD hh:mm:ss"'
        ORDER_ERROR = 'FromDate should be earlier than ToDate'
        INCOMING_DATE_ERROR = 'Date must be a DateTime or String in the format "YYYY-MM-DD" or "YYYY-MM-DD hh:mm:ss"'

        # -------------------------------------------------------------------
        # Creates a new ActiveRange based on +from_date+ and +to_date+
        # +from_date+ and +to_date+ must either be DateTime objects or parseable date strings
        #
        # <i>Exceptions</i>
        #   Will raise +ArgumentError+ if not a DateTime or parseable string or +from_date+ later than +to_date+
        # -------------------------------------------------------------------
        def initialize(from_date, to_date)
          f_d = prepare_date(from_date, FROM_DATE_ERROR)
          t_d = prepare_date(to_date, TO_DATE_ERROR)
          raise ArgumentError.new(ORDER_ERROR) if t_d < f_d
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
        # NOTE:
        # You can't use the '===' construct as ranges only support Dates,
        # Not DateAndTimes.
        # -------------------------------------------------------------------
        def in_range?(date)
          # Can't use ranges for date and time, only date
          # range = @from_date..@to_date
          # range === date # This doesn't work as expected
          d = prepare_date(date, INCOMING_DATE_ERROR)
          d >= @from_date and d <= @to_date
        end

        def ==(other)
          other.from_date == @from_date and other.to_date == @to_date
        end

        private

        def prepare_date(date, error_message)
          d = nil
          if date.is_a? DateTime or date.is_a? String
            if date.is_a? DateTime
              d = date
            else
              begin
                d = DateTime.parse(date) if date.is_a? String
              rescue TypeError
                raise ArgumentError.new(error_message)
              rescue ArgumentError
                raise ArgumentError.new(error_message)
              end
            end
          else
            raise ArgumentError.new(error_message)
          end
          d
        end

      end
    end
  end
end