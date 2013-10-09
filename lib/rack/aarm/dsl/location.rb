require 'resolv'

module Rack
  module AARM
    module DSL
      class Location
        attr_accessor :ipv4, :active_ranges

        MUST_BE_IPV4 = 'The IPv4 address must be a dotted numeric or dotted name'
        MUST_BE_ACTIVE_RANGE = 'The active_range must be an instance of Rack::AARM::DSL::ActiveRange'

        # -------------------------------------------------------------------
        # Creates a new Location based on +ipv4+
        # +ipv4+ can be either a dotted notation IPv4 address or a FQDN.
        # No testing past basic dotted numeric is done.
        #
        # <i>Exceptions</i>
        #   Will raise +ArgumentError+ if +ipv4+ is nil or
        #   numeric but not N.N.N.N
        # -------------------------------------------------------------------
        def initialize(ipv4)
          raise ArgumentError.new(MUST_BE_IPV4) if ipv4.nil?
          if ipv4.gsub(/\./, '') =~ /^[\d]+$/
            raise ArgumentError.new(MUST_BE_IPV4) unless ipv4 =~ /^[\d]+\.[\d]+\.[\d]+\.[\d]+$/
            raise ArgumentError.new(MUST_BE_IPV4) unless ipv4 =~ Resolv::IPv4::Regex
          end
          # After that, we can't do any more testing...
          @ipv4 = ipv4
          @active_ranges = []
        end

        # -------------------------------------------------------------------
        # Adds an +active_range+ to the location
        # Ignores duplicates.
        #
        # TODO: Disallow overlapping active ranges
        #
        # <i>Exceptions</i>
        #   Will raise +ArgumentError+ if +active_range+ is nil or
        #   not an +ActiveRange+
        # -------------------------------------------------------------------
        def add_active_range(active_range)
          raise ArgumentError.new(MUST_BE_ACTIVE_RANGE) if active_range.nil?
          raise ArgumentError.new(MUST_BE_ACTIVE_RANGE) unless active_range.is_a? Rack::AARM::DSL::ActiveRange
          @active_ranges << active_range unless @active_ranges.any? { |ar| ar == active_range }
          self
        end

        # -------------------------------------------------------------------
        # Removes an +active_range+ from the location
        # This is silent. That is, if the active range is not present, you
        # do not get any message
        #
        # <i>Exceptions</i>
        #   Will raise +ArgumentError+ if +active_range+ is nil or
        #   not an +ActiveRange+
        # -------------------------------------------------------------------
        def remove_active_range(active_range)
          raise ArgumentError.new(MUST_BE_ACTIVE_RANGE) if active_range.nil?
          raise ArgumentError.new(MUST_BE_ACTIVE_RANGE) unless active_range.is_a? Rack::AARM::DSL::ActiveRange
          @active_ranges.delete_if { |r| r == active_range }
          self
        end

      end
    end
  end
end

