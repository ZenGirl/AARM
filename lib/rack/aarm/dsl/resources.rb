module Rack
  module AARM
    module DSL
      class Resources
        attr_accessor :resources

        def initialize
          @resources = []
        end

        def add(resource)
          @resources << resource
        end

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

        def find(path)
          result = nil
          @resources.each { |resource| result = resource if path.start_with? resource.prefix }
          result
        end

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
      end
    end
  end
end
