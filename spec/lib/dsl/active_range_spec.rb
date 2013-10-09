require 'spec_helper'
require 'rspec'
require 'rack'
require 'rack/test'
require 'json'

require 'aarm'
require 'rack/aarm/dsl/active_range'

module Rack
  module AARM
    module DSL

      describe ActiveRange do

        context "It passes basic tests" do

          it "should raise an error if passed nils" do
            expect { ActiveRange.new(nil, nil) }.to raise_error ArgumentError, ActiveRange::FROM_DATE_ERROR
          end

          it "should raise an error if from or to are not DateTimes" do
            expect { ActiveRange.new(12345, 67.89) }.to raise_error ArgumentError, ActiveRange::FROM_DATE_ERROR
          end

          it "should raise an error if from or to are nils" do
            expect { ActiveRange.new(nil, DateTime.now) }.to raise_error ArgumentError, ActiveRange::FROM_DATE_ERROR
            expect { ActiveRange.new(DateTime.now, nil) }.to raise_error ArgumentError, ActiveRange::TO_DATE_ERROR
          end

          it "should raise an error if from or to are unparseable" do
            expect { ActiveRange.new('Not a real date', DateTime.now) }.to raise_error ArgumentError, ActiveRange::FROM_DATE_ERROR
            expect { ActiveRange.new(DateTime.now, 'not a real date') }.to raise_error ArgumentError, ActiveRange::TO_DATE_ERROR
          end

          it "should raise an error if from date is later that to date" do
            expect { ActiveRange.new(DateTime.new(2013, 10, 1), DateTime.new(1970, 1, 1)) }.to raise_error ArgumentError, ActiveRange::ORDER_ERROR
          end

          it "should raise an error if range test is passed a non DateTime or parseable String" do
            expect { ActiveRange.for_all_time.in_range?(nil) }.to raise_error ArgumentError, ActiveRange::INCOMING_DATE_ERROR
            expect { ActiveRange.for_all_time.in_range?(1246546) }.to raise_error ArgumentError, ActiveRange::INCOMING_DATE_ERROR
            expect { ActiveRange.for_all_time.in_range?('not a real date') }.to raise_error ArgumentError, ActiveRange::INCOMING_DATE_ERROR
          end

        end

      end
    end
  end
end
