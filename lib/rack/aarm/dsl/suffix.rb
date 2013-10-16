module Rack
  module AARM
    module DSL
      class Suffix
        attr_accessor :regex, :verbs, :caller

        # -------------------------------------------------------------------
        # Need the helpers
        # -------------------------------------------------------------------
        require_relative 'helpers'
        include Rack::AARM::DSL::Helpers

        # -------------------------------------------------------------------
        # Create a new suffix
        # -------------------------------------------------------------------
        def initialize(regex)
          raise ArgumentError.new(Rack::AARM::DSL::Helpers::ARGUMENTS_BAD) unless regex.is_a? Regexp
          @regex = regex
          @verbs = []
        end

        # -------------------------------------------------------------------
        # Add a verb
        # -------------------------------------------------------------------
        def add_verb(verb)
          obj = Verb.new(verb)
          obj.add_binding(binding().eval('self'))
          @verbs << obj
          obj
        end

        # -------------------------------------------------------------------
        # Is the verb available?
        # -------------------------------------------------------------------
        def has_verb?(verb)
          @verbs.any? { |v| v.name == verb }
        end

        # -------------------------------------------------------------------
        # Remove a verb
        # -------------------------------------------------------------------
        def remove_verb(verb)
          @verbs.delete_if { |v| v.name == verb }
          self
        end

        def to_hash
          hash = {
              regex: @regex, verbs: []
          }
          @verbs.each do |verb|
            hash[:verbs] << verb.to_hash
          end
          hash
        end

      end
    end
  end
end
