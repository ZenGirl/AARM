module Rack
  module AARM
    module DSL
      class Vendors
        attr_accessor :vendors

        # -------------------------------------------------------------------
        # Need the helpers
        # -------------------------------------------------------------------
        require_relative 'helpers'
        include Rack::AARM::DSL::Helpers

        # -------------------------------------------------------------------
        # Create a new block of vendors and resources
        # -------------------------------------------------------------------
        def initialize
          @vendors = []
        end

        # -------------------------------------------------------------------
        # Add a vendor
        # -------------------------------------------------------------------
        def add(vendor)
          @vendors << vendor
        end

        # -------------------------------------------------------------------
        # Does the vendor exist?
        # -------------------------------------------------------------------
        def exist?(name)
          @vendors.any? { |vendor| vendor.name == name }
        end

        # -------------------------------------------------------------------
        # Does the vendor exist by id?
        # -------------------------------------------------------------------
        def find(id)
          result = nil
          @vendors.each do |vendor|
            result = vendor if vendor.id == id
          end
          result
        end

        # -------------------------------------------------------------------
        # Does the vendor exist by key?
        # -------------------------------------------------------------------
        def find_by_key(key)
          result = nil
          @vendors.each do |vendor|
            result = vendor if vendor.vendor_keys.any? { |k| k.key == key }
          end
          result
        end

        def each(&block)
          @vendors.each(&block)
        end

        def to_hash
          hash = []
          @vendors.each do |vendor|
            hash << vendor.to_hash
          end
          hash
        end

      end
    end
  end
end

