require 'spec_helper'
require 'rspec'
require 'rack'
require 'rack/test'
require 'json'

require 'aarm'
require 'rack/aarm/dsl/resource'

module Rack
  module AARM
    module DSL

      describe Resources do

        context "It passes basic tests" do

          it "should allow adding resource(s)" do
            resource = Resource.new(1, 'billings.active', '/billings/api/v1')
            resources = Resources.new
            expect { resources.add(resource) }.not_to raise_error
          end

          it "should respond correctly to active ranges" do
            resources = Resources.new
            resource = Resource.new(1, 'billings.active', '/billings/api/v1')
            suffix = resource.add_suffix(Regexp.new('^\/banks$'))
            suffix.add_verb('GET').add_active_range(Rack::AARM::DSL::ActiveRange.for_all_time)
            suffix.add_verb('POST').add_active_range(Rack::AARM::DSL::ActiveRange.for_all_time)
            suffix.add_verb('HEAD').add_active_range(Rack::AARM::DSL::ActiveRange.for_all_time)
            suffix = resource.add_suffix(Regexp.new('^\/banks/[\d]+$'))
            suffix.add_verb('GET').add_active_range(Rack::AARM::DSL::ActiveRange.for_all_time)
            resources.add(resource)

            expect(resources.find_full('/billings/api/v1/banks', 'GET')).to be_true
            expect(resources.find_full('/billings/api/v1/bugger', 'GET')).to be_false
            expect(resources.find_full('/billings/api/v1/banks/12345', 'GET')).to be_true
            expect(resources.find_full('/billings/api/v1/banks/12345', 'POST')).to be_false

            expect(resources.is_active?('/billings/api/v1/banks', '2013-10-01', 'GET')).to be_true
            expect(resources.is_active?('/billings/api/v1/banks/12345', '2013-10-01', 'GET')).to be_true
          end

        end

      end
    end
  end
end
