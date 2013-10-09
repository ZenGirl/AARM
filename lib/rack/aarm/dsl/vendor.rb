module Rack
  module AARM
    module DSL
      class Vendor
        attr_accessor :id, :name, :keys, :active_ranges, :use_locations, :locations, :roles
        attr_accessor :resources

        def initialize(id, name)
          @id, @name = id, name
          @keys, @active_ranges, @use_locations, @locations, @roles = [], [], false, [], []
          @resources = []
        end

        def add_key(active_range, key, secret)
          @keys << VendorKey.new(active_range, key, secret)
          self
        end

        def add_active_range(active_range)
          @active_ranges << active_range
          self
        end

        def make_restricted_by_locations
          @use_locations = true
          self
        end

        def add_location(location)
          @locations << location
          self
        end

        def add_role(name, password_plain, password_md5)
          role = Role.new(name, password_plain, password_md5)
          role.add_binding(binding().eval('self'))
          @roles << role
          role
        end

        def active_on?(date)
          d = date
          d = DateTime.parse(date) if date.is_a? String
          @active_ranges.any? { |active_range| active_range.in_range? d }
        end

        def uses_locations?
          @use_locations
        end

        def allowed_from?(ipv4, on_date)
          return true unless @use_locations
          d = on_date
          d = DateTime.parse(on_date) if on_date.is_a? String
          @locations.each do |location|
            return location.active_ranges.any? { |active_range| active_range.in_range? d } if location.ipv4 == ipv4
          end
          false
        end

        def find_role(name, password_md5)
          @roles.each do |role|
            return role if role.name == name and role.password_md5 == password_md5
          end
          nil
        end

        def can_access?(opts={})
          return false unless active_on? opts[:on]
          return false unless allowed_from? opts[:ipv4], opts[:on]
          role = find_role opts[:role], opts[:pass]
          return false if role.nil?
          return false unless role.active_on? opts[:on]
          path_allowed = false
          role.rights.each do |right|
            if right.verbs.include? opts[:via]
              path_allowed = true if resources.is_active? opts[:path], opts[:on], opts[:via]
            end
          end
          return false unless path_allowed
          true
        end
      end
    end
  end
end

