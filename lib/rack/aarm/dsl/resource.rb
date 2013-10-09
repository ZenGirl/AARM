module Rack
  module AARM
    module DSL
      class Resource
        attr_accessor :id, :name, :prefix, :suffixes

        def initialize(id, name, prefix)
          @id, @name, @prefix = id, name, prefix
          @suffixes = []
        end

        def add_suffix(path_regex)
          obj = Suffix.new(path_regex)
          @suffixes << obj
          obj
        end

      end
    end
  end
end
