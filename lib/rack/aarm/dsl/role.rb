module Rack
  module AARM
    module DSL
      class Role
        attr_accessor :name, :password_plain, :password_md5, :active_ranges, :rights

        def initialize(name, password_plain, password_md5)
          @name, @password_plain, @password_md5 = name, password_plain, password_md5
          @active_ranges, @rights = [], []
        end

        def add_active_range(active_range)
          @active_ranges << active_range
          self
        end

        def add_rights(verbs, resources)
          @rights << RoleRight.new(verbs, resources)
          self
        end

        def active_on?(date)
          d = date
          d = DateTime.parse(date) if date.is_a? String
          @active_ranges.any? { |active_range| active_range.in_range? d }
        end


        def add_binding(caller)
          @caller = caller
        end

        def back_to_vendor
          @caller
        end
      end
    end
  end
end

