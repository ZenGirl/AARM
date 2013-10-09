module Rack
  module AARM
    module DSL
      class Suffix
        attr_accessor :regex, :verbs, :caller

        def initialize(regex)
          @regex = regex
          @verbs = []
        end

        def add_verb(verb)
          obj = Verb.new(verb)
          obj.add_binding(binding().eval('self'))
          @verbs << obj
          obj
        end

        def has_verb?(verb)
          @verbs.any? { |v| v.name == verb }
        end

        def remove_verb(verb)
          @verbs.delete_if { |v| v.name == verb }
          self
        end

      end
    end
  end
end
