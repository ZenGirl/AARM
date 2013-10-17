require 'spec_helper'
require 'rspec'
require 'rack'
require 'rack/test'
require 'json'

require 'aarm'
require 'rack/aarm/dsl/vendors'
require 'rack/aarm/dsl/vendor'

module Rack
  module AARM
    module DSL

      describe Vendors do

        context "It passes basic tests" do

          it "should allow adding vendor(s)" do
            resources = Resources.new
            expect { resources.add(nil) }.to raise_error ArgumentError, Rack::AARM::DSL::Helpers::ARGUMENTS_BAD
            resource = Resource.new(1, 'billings.active', '/billings/api/v1')
            expect { resources.add(resource) }.not_to raise_error

            vendors = Vendors.new
            vendor = Vendor.new(1, 'Gumby')
            #vendor.add_active_range(ActiveRange.new('2013-10-01', '2013-10-10')).add_active_range(ActiveRange.new('2013-10-20', '2013-10-29'))
            expect { vendors.add(vendor) }.not_to raise_error

          end

          it "should respond correctly to searching for vendors" do
            vendors = Vendors.new
            vendor1 = Vendor.new(1, 'Gumby')
            vendor1.add_key(ActiveRange.for_all_time, "QOYNT/+GeMBQJzX+QSBuEA==", "MpzZMi+Aug6m/vd5VYdHrA==")
            #vendor1.add_active_range(ActiveRange.new('2013-10-01', '2013-10-10')).add_active_range(ActiveRange.new('2013-10-20', '2013-10-29'))
            vendors.add(vendor1)
            vendor2 = Vendor.new(2, 'Gonzo')
            vendor2.add_key(ActiveRange.new('2013-10-01', '2013-10-31'), "wBxPg1il07wNMdkClLWsqg==", "q9cqANbXvthP6ypSMwQ3ow==")
            #vendor2.add_active_range(ActiveRange.new('2013-10-01', '2013-10-10')).add_active_range(ActiveRange.new('2013-10-20', '2013-10-29'))
            vendors.add(vendor2)

            expect(vendors.exist?('Gumby')).to be_true
            expect(vendors.exist?('Gonzo')).to be_true
            expect(vendors.exist?('Frank')).to be_false

            expect(vendors.find(1)).to be_true
            expect(vendors.find(2)).to be_true
            expect(vendors.find(3)).to be_false

            expect(vendors.find_by_key('QOYNT/+GeMBQJzX+QSBuEA==')).to be_true
            expect(vendors.find_by_key('wBxPg1il07wNMdkClLWsqg==')).to be_true
            expect(vendors.find_by_key('NOT_A_REAK_KEY')).to be_false
          end

        end

      end
    end
  end
end
