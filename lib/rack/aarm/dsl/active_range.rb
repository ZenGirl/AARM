module Rack
  module AARM
    module DSL
      class ActiveRange
        attr_accessor :from_date, :to_date

        def initialize(from_date, to_date)
          f_d = from_date
          f_d = DateTime.parse(from_date) if from_date.is_a? String
          t_d = to_date
          t_d = DateTime.parse(to_date) if to_date.is_a? String
          @from_date, @to_date = f_d, t_d
        end

        def self.for_all_time
          new(all_past, all_future)
        end

        def self.all_past
          DateTime.new(1970, 1, 1)
        end

        def self.all_future
          DateTime.new(2100, 1, 1)
        end

        def in_range?(date)
          # ARGH. Can't use ranges for date and time, only date
          #range = @from_date..@to_date
          #puts "[#{range}][#{date}]"
          #range === date
          d = date
          d = DateTime.parse(date) if date.is_a? String
          d >= @from_date and d <= @to_date
        end
      end
    end
  end
end