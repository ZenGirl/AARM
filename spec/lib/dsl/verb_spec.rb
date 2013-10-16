require 'spec_helper'
require 'rspec'
require 'rack'
require 'rack/test'
require 'json'

require 'aarm'
require 'rack/aarm/dsl/verb'

module Rack
  module AARM
    module DSL

      describe Verb do

        context "It passes basic tests" do

          it "should raise an error if passed invalid arguments" do
            expect { Verb.new(nil) }.to raise_error ArgumentError, Rack::AARM::DSL::Helpers::ARGUMENTS_BAD
            expect { Verb.new('NOT_A_HTTP_VERB') }.to raise_error ArgumentError, Rack::AARM::DSL::Helpers::ARGUMENTS_BAD
          end

          it "should allow adding active ranges" do
            verb = Verb.new('GET')
            range1 = ActiveRange.new('2013-10-01', '2013-10-10')
            range2 = ActiveRange.new('2013-10-20', '2013-10-29')
            verb.add_active_range(range1).add_active_range(range2)
            expect(verb.active_ranges.size).to eql(2)
          end

          it "should respond correctly to various active_ranges" do
            verb = Verb.new('GET')
            range1 = ActiveRange.new('2013-10-01', '2013-10-10')
            range2 = ActiveRange.new('2013-10-20', '2013-10-29')
            verb.add_active_range(range1).add_active_range(range2)
            (1..10).each do |dd|
              expect(verb.active_on? "2013-10-%02d" % dd).to be_true
            end
            (11..19).each do |dd|
              expect(verb.active_on? "2013-10-%02d" % dd).to be_false
            end
            (20..29).each do |dd|
              expect(verb.active_on? "2013-10-%02d" % dd).to be_true
            end
          end

        end

      end
    end
  end
end
