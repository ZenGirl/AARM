require 'spec_helper'
require 'rspec'
require 'rack'
require 'rack/test'
require 'json'

require 'aarm'
require 'rack/aarm/dsl/suffix'

module Rack
  module AARM
    module DSL

      describe Verb do

        context "It passes basic tests" do

          it "should raise an error if passed invalid arguments" do
            expect { Suffix.new(nil) }.to raise_error ArgumentError, Rack::AARM::DSL::Helpers::ARGUMENTS_BAD
            expect { Suffix.new('') }.to raise_error ArgumentError, Rack::AARM::DSL::Helpers::ARGUMENTS_BAD
          end

          it "should allow adding verbs" do
            suffix = Suffix.new(Regexp.new('^\/banks$'))
            expect { suffix.add_verb(nil) }.to raise_error ArgumentError, Rack::AARM::DSL::Helpers::ARGUMENTS_BAD

            suffix.add_verb('GET')
            expect(suffix.has_verb?('POST')).to be_false
            expect(suffix.has_verb?('GET')).to be_true
            suffix.remove_verb('GET')
            expect(suffix.has_verb?('GET')).to be_false
          end

        end

      end
    end
  end
end
