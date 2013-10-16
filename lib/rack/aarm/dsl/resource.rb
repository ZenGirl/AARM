module Rack
  module AARM
    module DSL
      class Resource
        attr_accessor :id, :name, :prefix, :suffixes

        # -------------------------------------------------------------------
        # Need the helpers
        # -------------------------------------------------------------------
        require_relative 'helpers'
        include Rack::AARM::DSL::Helpers

        # -------------------------------------------------------------------
        # Create a new Resource
        # -------------------------------------------------------------------
        def initialize(id, name, prefix)
          raise ArgumentError.new(Rack::AARM::DSL::Helpers::ARGUMENTS_BAD) if id.nil? or !id.is_a? Integer or id < 0
          raise ArgumentError.new(Rack::AARM::DSL::Helpers::ARGUMENTS_BAD) unless name.is_a? String and !name.strip.blank?
          raise ArgumentError.new(Rack::AARM::DSL::Helpers::ARGUMENTS_BAD) unless prefix.is_a? String and !prefix.strip.blank?
          @id, @name, @prefix = id, name, prefix
          @suffixes = []
        end

        # -------------------------------------------------------------------
        # Add a suffix
        # -------------------------------------------------------------------
        def add_suffix(path_regex)
          obj = Suffix.new(path_regex)
          @suffixes << obj
          obj
        end

      end
    end
  end
end
