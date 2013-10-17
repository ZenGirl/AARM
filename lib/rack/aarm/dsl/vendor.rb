module Rack # :nodoc: so we don't have an empty doc page for the namespace
  module AARM # :nodoc:
    module DSL # :nodoc:

      # ---------------------------------------------------------------------
      # Describes a vendor and all their attributes
      #
      # <i>Example Usage:</i>
      #   See +/doc/aarm_-_authentication_authorisation_rack_middleware.html+
      # ---------------------------------------------------------------------
      class Vendor
        attr_accessor :id, :name, :vendor_keys, :use_locations, :locations, :roles

        # -------------------------------------------------------------------
        # Need the helpers
        # -------------------------------------------------------------------
        require_relative 'helpers'
        include Rack::AARM::DSL::Helpers

        # -------------------------------------------------------------------
        # We use locations and active_range
        # -------------------------------------------------------------------
        require_relative 'location'
        require_relative 'active_range'
        require_relative 'vendor_key'
        require_relative 'role'
        require_relative 'role_right'

        # -------------------------------------------------------------------
        # Creates a new Vendor based on an +id+ and +name+
        # <i>Note:</i>
        #   No testing is done for duplicates
        #
        # <i>Variable Defaults:</i>
        #   keys = [], active_ranges = [], roles = []
        #   use_locations = false, locations = []
        #
        #TODO: Check for duplicates? How?
        # -------------------------------------------------------------------
        def initialize(id, name)
          raise ArgumentError.new(Rack::AARM::DSL::Helpers::VENDOR_ID_BAD) if id.nil? or !id.is_a? Integer or id < 1
          raise ArgumentError.new(Rack::AARM::DSL::Helpers::VENDOR_NAME_BAD) if name.nil? or !name.is_a? String or name.strip.blank?
          @id, @name = id, name
          @vendor_keys, @use_locations, @locations, @roles = [], false, [], []
          @resources = []
        end

        # -------------------------------------------------------------------
        # Adds an API-KEY and and API-SECRET for a specified date range
        # Method is chainable.
        # -------------------------------------------------------------------
        def add_key(active_range, key, secret)
          @vendor_keys << VendorKey.new(active_range, key, secret)
          self
        end

        # -------------------------------------------------------------------
        # Makes this vendor restricted to locations
        # Method is chainable.
        # -------------------------------------------------------------------
        def make_restricted_by_locations
          @use_locations = true
          self
        end

        # -------------------------------------------------------------------
        # Makes this vendor unrestricted by locations
        # Method is chainable.
        # -------------------------------------------------------------------
        def make_unrestricted_by_locations
          @use_locations = false
          self
        end

        # -------------------------------------------------------------------
        # Checks to see if this vendor is restricted by locations
        # -------------------------------------------------------------------
        def uses_locations?
          @use_locations
        end

        # -------------------------------------------------------------------
        # Adds an active_range location to this vendor
        # Method is chainable.
        # -------------------------------------------------------------------
        def add_location(location)
          raise ArgumentError.new(Rack::AARM::DSL::Helpers::ARGUMENTS_BAD) unless location.is_a? Rack::AARM::DSL::Location
          @locations << location
          self
        end

        # -------------------------------------------------------------------
        # Checks to see if this vendor is allowed from a specific IPv4
        # address on a specific date
        # -------------------------------------------------------------------
        def allowed_from?(ipv4, on_date)
          return true unless @use_locations
          d = prepare_date(on_date, Rack::AARM::DSL::Helpers::INCOMING_DATE_ERROR)
          @locations.each do |location|
            return location.active_ranges.any? { |active_range| active_range.in_range? d } if location.ipv4 == ipv4
          end
          false
        end

        # -------------------------------------------------------------------
        # Adds a role name, plain and md5 password
        # Method is chainable through roles - See +Role+.
        # -------------------------------------------------------------------
        def add_role(name, password_plain, password_md5)
          role = Role.new(name, password_plain, password_md5)
          role.add_binding(binding().eval('self')) # Allows back-tracking from roles back to vendor
          @roles << role
          role
        end

        # -------------------------------------------------------------------
        # Checks to see if this vendor has an active range that includes
        # the DateTime argument +date+
        # -------------------------------------------------------------------
        def active_on?(date)
          d = prepare_date(date, Rack::AARM::DSL::Helpers::INCOMING_DATE_ERROR)
          active_in_keys = @vendor_keys.any? { |key| key.active_range.in_range? d}
          active_in_keys
        end

        def first_active_key(date)
          d = prepare_date(date, Rack::AARM::DSL::Helpers::INCOMING_DATE_ERROR)
          @vendor_keys.each do |key|
            return key if key.active_range.in_range? d
          end
          nil
        end

        # -------------------------------------------------------------------
        # Finds a role
        # -------------------------------------------------------------------
        def find_role(name, password_md5)
          @roles.each do |role|
            return role if role.name == name and role.password_md5 == password_md5
          end
          nil
        end

        # -------------------------------------------------------------------
        # Whizz bang whole test
        # -------------------------------------------------------------------
        def can_access?(resources, opts={})
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

        def to_hash
          hash = {
              id: @id, name: @name, vendor_keys: [], active_ranges: [], use_locations: @use_locations, locations: [], roles: []
          }
          @vendor_keys.each { |obj| hash[:vendor_keys] << obj.to_hash }
          @locations.each { |key| hash[:locations] << key.to_hash }
          @roles.each { |key| hash[:roles] << key.to_hash }
          hash
        end

      end
    end
  end
end

