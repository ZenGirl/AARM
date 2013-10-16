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

      describe Resource do

        context "It passes basic tests" do

          it "should raise an error if passed invalid arguments" do
            expect { Resource.new(nil, nil, nil) }.to raise_error ArgumentError, Rack::AARM::DSL::Helpers::ARGUMENTS_BAD
            expect { Resource.new(-1, nil, nil) }.to raise_error ArgumentError, Rack::AARM::DSL::Helpers::ARGUMENTS_BAD
            expect { Resource.new(1, '', nil) }.to raise_error ArgumentError, Rack::AARM::DSL::Helpers::ARGUMENTS_BAD
            expect { Resource.new(1, 'name', nil) }.to raise_error ArgumentError, Rack::AARM::DSL::Helpers::ARGUMENTS_BAD
            expect { Resource.new(1, 'name', '') }.to raise_error ArgumentError, Rack::AARM::DSL::Helpers::ARGUMENTS_BAD
            expect { Resource.new(1, 'name', 'prefix') }.not_to raise_error
          end

          it "should allow adding suffixes" do
            resource = Resource.new(1, 'billings.active', '/billings/api/v1')
            expect { resource.add_suffix(Regexp.new('^\/banks$')) }.not_to raise_error
          end

        end

      end
    end
  end
end
