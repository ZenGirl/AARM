require 'spec_helper'
require 'rspec'
require 'rack'
require 'rack/test'
require 'json'

require 'aarm'
require 'rack/aarm/dsl/role_right'

module Rack
  module AARM
    module DSL

      describe RoleRight do

        context "It passes basic tests" do

          it "should raise an error if passed invalid arguments" do
            expect { RoleRight.new(nil, nil) }.to raise_error ArgumentError, Rack::AARM::DSL::Helpers::ARGUMENTS_BAD
            expect { RoleRight.new(%w(NOT REAL HTTP VERBS), nil) }.to raise_error ArgumentError, Rack::AARM::DSL::Helpers::ARGUMENTS_BAD
            expect { RoleRight.new(%w(GET PUT POST DELETE), [
                Resource.new(1,'',''),
                nil,
                ''
            ]) }.to raise_error ArgumentError, Rack::AARM::DSL::Helpers::ARGUMENTS_BAD
          end

        end

      end
    end
  end
end
