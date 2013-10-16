require 'json'

module Rack
  module AARM
    module DSL
      class Resources
        attr_accessor :resources

        # -------------------------------------------------------------------
        # Need the helpers
        # -------------------------------------------------------------------
        require_relative 'helpers'
        include Rack::AARM::DSL::Helpers

        # -------------------------------------------------------------------
        # Create a new block of resources
        # -------------------------------------------------------------------
        def initialize
          @resources = []
        end

        # -------------------------------------------------------------------
        # Add a resource
        # -------------------------------------------------------------------
        def add(resource)
          raise ArgumentError.new(Rack::AARM::DSL::Helpers::ARGUMENTS_BAD) unless resource.is_a? Rack::AARM::DSL::Resource
          @resources << resource
        end

        # -------------------------------------------------------------------
        # Is resource active?
        # -------------------------------------------------------------------
        def is_active?(path, date, verb)
          results = find_full(path, verb)
          return false if results.nil?
          results.each do |result|
            result.verbs.each do |v|
              return true if v.name == verb and v.active_ranges.any? { |active_range| active_range.in_range?(date) }
            end
          end
          false
        end

        # -------------------------------------------------------------------
        # Find one
        # -------------------------------------------------------------------
        def find(path)
          result = nil
          @resources.each { |resource| result = resource if path.start_with? resource.prefix }
          result
        end

        # -------------------------------------------------------------------
        # Find a verb path
        # -------------------------------------------------------------------
        def find_full(path, verb=nil)
          results = []
          @resources.each do |resource|
            next unless path.start_with? resource.prefix
            tail_end = path.gsub(resource.prefix, '')
            resource.suffixes.each do |suffix|
              results << suffix if tail_end =~ suffix.regex and (verb.nil? ? true : suffix.has_verb?(verb))
            end
          end
          results.size == 0 ? nil : results
        end

        def to_hash
          hash = []
          @resources.each do |resource|
            hash << resource.to_hash
          end
          hash
        end

      end
    end
  end
end
