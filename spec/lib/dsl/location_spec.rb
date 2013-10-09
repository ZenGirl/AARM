require 'spec_helper'
require 'rspec'
require 'rack'
require 'rack/test'
require 'json'

require 'aarm'
require 'rack/aarm/dsl/location'

module Rack
  module AARM
    module DSL

      describe Location do

        context "It passes basic tests" do

          it "should raise an error if passed non string" do
            expect { _ = Location.new(nil) }.to raise_error ArgumentError, Location::MUST_BE_IPV4
          end

          it "should raise an error if passed an invalid dotted IPv4 address" do
            expect { _ = Location.new('1.2.3.4.5') }.to raise_error ArgumentError, Location::MUST_BE_IPV4
          end

          it "should not raise an error if passed an dotted string" do
            expect { _ = Location.new('local.name.of.some.company.com') }.not_to raise_error
          end

          it "should raise error if not adding valid active ranges" do
            expect { _ = Location.new('127.0.0.1').add_active_range(nil) }.to raise_error ArgumentError, Location::MUST_BE_ACTIVE_RANGE
          end

          it "correctly adds and removes active ranges" do
            location = Location.new('127.0.0.1')

            # Add one
            location.add_active_range(ActiveRange.for_all_time)
            expect( location.active_ranges.size ).to eql(1)

            # Ignore duplicates
            location.add_active_range(ActiveRange.for_all_time)
            expect( location.active_ranges.size ).to eql(1)

            # Delete it
            location.remove_active_range(ActiveRange.for_all_time)
            expect( location.active_ranges.size ).to eql(0)
          end

        end

      end
    end
  end
end
