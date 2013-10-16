module Rack # :nodoc: so we don't have an empty doc page for the namespace
  module AARM # :nodoc:
    module DSL # :nodoc:
      module Helpers # :nodoc:

        # ---------------------------------------------------------------------
        # DSL Helpers
        # ---------------------------------------------------------------------

        # ---------------------------------------------------------------------
        # Error messages
        # ---------------------------------------------------------------------
        FROM_DATE_ERROR = 'FromDate must be a DateTime or String in the format "YYYY-MM-DD" or "YYYY-MM-DD hh:mm:ss"'
        TO_DATE_ERROR = 'ToDate must be a DateTime or String in the format "YYYY-MM-DD" or "YYYY-MM-DD hh:mm:ss"'
        ORDER_ERROR = 'FromDate should be earlier than ToDate'
        INCOMING_DATE_ERROR = 'Date must be a DateTime or String in the format "YYYY-MM-DD" or "YYYY-MM-DD hh:mm:ss"'
        ARGUMENTS_BAD = 'The method was passed incompatible arguments - see the documentation'
        MUST_BE_IPV4 = 'The IPv4 address must be a dotted numeric or dotted name'
        MUST_BE_ACTIVE_RANGE = 'The active_range must be an instance of Rack::AARM::DSL::ActiveRange'
        VENDOR_ID_BAD = 'Vendor id must be an Integer (1+)'
        VENDOR_NAME_BAD = 'Vendor name must be a non empty String'

        # -------------------------------------------------------------------
        # Checks a value and:
        # 1. ensures it is a DateTime or String
        # 2. if a String, parses it
        # 3. Otherwise throw an ArgumentError
        #
        # <i>Exceptions</i>
        #   Will raise +ArgumentError+ if not a DateTime or parseable string
        # -------------------------------------------------------------------
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
