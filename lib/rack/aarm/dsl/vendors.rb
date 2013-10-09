module Rack
  module AARM
    module DSL
      class Vendors
        attr_accessor :vendors, :resources

        def initialize
          @vendors = []
          @resources = []
        end

        def add(vendor)
          vendor.resources = @resources
          @vendors << vendor
        end

        def exist?(name)
          @vendors.any? { |vendor| vendor.name == name }
        end

        def find(id)
          result = nil
          @vendors.each do |vendor|
            result = vendor if vendor.id == id
          end
          result
        end

        def find_by_name(name)
          result = nil
          @vendors.each do |vendor|
            result = vendor if vendor.name == name
          end
          result
        end

        def find_by_key(key)
          result = nil
          @vendors.each do |vendor|
            result = vendor if vendor.keys.any? { |k| k.key == key }
          end
          result
        end
      end
    end
  end
end

