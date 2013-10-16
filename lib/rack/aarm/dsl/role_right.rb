module Rack
  module AARM
    module DSL
      class RoleRight
        attr_accessor :verbs, :on_resources

        # -------------------------------------------------------------------
        # Need the helpers
        # -------------------------------------------------------------------
        require_relative 'helpers'
        include Rack::AARM::DSL::Helpers

        # -------------------------------------------------------------------
        # Create a new role
        # -------------------------------------------------------------------
        def initialize(verbs, resources)
          raise ArgumentError.new(Rack::AARM::DSL::Helpers::ARGUMENTS_BAD) unless verbs.is_a? Array
          verbs.each { |verb| raise ArgumentError.new(Rack::AARM::DSL::Helpers::ARGUMENTS_BAD) unless %w(GET POST PUT DELETE).include? verb }
          raise ArgumentError.new(Rack::AARM::DSL::Helpers::ARGUMENTS_BAD) unless resources.is_a? Array
          resources.each { |resource| raise ArgumentError.new(Rack::AARM::DSL::Helpers::ARGUMENTS_BAD) unless resource.is_a? Rack::AARM::DSL::Resource }
          @verbs, @on_resources = verbs, resources
        end
      end
    end
  end
end

