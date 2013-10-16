module Rack
  module AARM
    module DSL
      class Role
        attr_accessor :name, :password_plain, :password_md5, :active_ranges, :rights

        # -------------------------------------------------------------------
        # Need the helpers
        # -------------------------------------------------------------------
        require_relative 'helpers'
        include Rack::AARM::DSL::Helpers

        # -------------------------------------------------------------------
        # We use these
        # -------------------------------------------------------------------
        require_relative 'role_right'

        # -------------------------------------------------------------------
        # Create a new role
        # -------------------------------------------------------------------
        def initialize(name, password_plain, password_md5)
          raise ArgumentError.new(Rack::AARM::DSL::Helpers::ARGUMENTS_BAD) unless name.is_a? String and name.strip.size > 0
          raise ArgumentError.new(Rack::AARM::DSL::Helpers::ARGUMENTS_BAD) unless password_plain.is_a? String and password_plain.strip.size > 0
          raise ArgumentError.new(Rack::AARM::DSL::Helpers::ARGUMENTS_BAD) unless password_md5.is_a? String and password_md5.strip.size > 0
          @name, @password_plain, @password_md5 = name, password_plain, password_md5
          @active_ranges, @rights = [], []
        end

        # -------------------------------------------------------------------
        # Add an active range
        # -------------------------------------------------------------------
        def add_active_range(active_range)
          raise ArgumentError.new(Rack::AARM::DSL::Helpers::ARGUMENTS_BAD) unless active_range.is_a? Rack::AARM::DSL::ActiveRange
          @active_ranges << active_range
          self
        end

        # -------------------------------------------------------------------
        # Add some rights
        # Expects resources to be an array of +Resource+
        # -------------------------------------------------------------------
        def add_rights(verbs, resources)
          @rights << RoleRight.new(verbs, resources)
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
        def back_to_vendor
          @caller
        end

        def to_hash
          hash = {
              name: @name, password_plain: @password_plain, password_md5: @password_md5, active_ranges: [], rights: []
          }
          @active_ranges.each { |key| hash[:active_ranges] << key.to_hash }
          @rights.each { |key| hash[:rights] << key.to_hash }
          hash
        end

      end
    end
  end
end

