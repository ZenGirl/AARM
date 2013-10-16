require 'spec_helper'
require 'rspec'
require 'rack'
require 'rack/test'
require 'json'

require 'aarm'
require 'rack/aarm/dsl/vendor'

module Rack
  module AARM
    module DSL

      describe Vendor do

        context "It passes basic tests" do

          require_relative '../../../lib/rack/aarm/dsl/helpers'
          include Rack::AARM::DSL::Helpers

          it "should raise an error if passed nils" do
            expect { Vendor.new(nil, nil) }.to raise_error ArgumentError, Rack::AARM::DSL::Helpers::VENDOR_ID_BAD
            expect { Vendor.new(nil, '') }.to raise_error ArgumentError, Rack::AARM::DSL::Helpers::VENDOR_ID_BAD
            expect { Vendor.new(nil, 2000) }.to raise_error ArgumentError, Rack::AARM::DSL::Helpers::VENDOR_ID_BAD
            expect { Vendor.new(1, nil) }.to raise_error ArgumentError, Rack::AARM::DSL::Helpers::VENDOR_NAME_BAD
            expect { Vendor.new(2000, nil) }.to raise_error ArgumentError, Rack::AARM::DSL::Helpers::VENDOR_NAME_BAD
          end

          it "should raise an error if arguments are not valid" do
            expect { Vendor.new(-1, 'gumby') }.to raise_error ArgumentError, Rack::AARM::DSL::Helpers::VENDOR_ID_BAD
            expect { Vendor.new('Not an integer', 'gumby') }.to raise_error ArgumentError, Rack::AARM::DSL::Helpers::VENDOR_ID_BAD
            expect { Vendor.new(100, '') }.to raise_error ArgumentError, Rack::AARM::DSL::Helpers::VENDOR_NAME_BAD
            expect { Vendor.new(100, Time.new) }.to raise_error ArgumentError, Rack::AARM::DSL::Helpers::VENDOR_NAME_BAD
          end

          it "should raise errors if adding keys arguments are not valid" do
            vendor = Vendor.new(1, 'Gumby')
            range = ActiveRange.new('2013-10-01', '2013-10-10')
            expect { vendor.add_key(nil, nil, nil) }.to raise_error ArgumentError, Rack::AARM::DSL::Helpers::ARGUMENTS_BAD
            expect { vendor.add_key('not an active_range', nil, nil) }.to raise_error ArgumentError, Rack::AARM::DSL::Helpers::ARGUMENTS_BAD
            expect { vendor.add_key(range, nil, nil) }.to raise_error ArgumentError, Rack::AARM::DSL::Helpers::ARGUMENTS_BAD
            expect { vendor.add_key(range, '', nil) }.to raise_error ArgumentError, Rack::AARM::DSL::Helpers::ARGUMENTS_BAD
            expect { vendor.add_key(range, 'API_KEY', nil) }.to raise_error ArgumentError, Rack::AARM::DSL::Helpers::ARGUMENTS_BAD
            expect { vendor.add_key(range, 'API_KEY', '') }.to raise_error ArgumentError, Rack::AARM::DSL::Helpers::ARGUMENTS_BAD
          end

          it "should allow adding active ranges" do
            vendor = Vendor.new(1, 'Gumby')
            range1 = ActiveRange.new('2013-10-01', '2013-10-10')
            range2 = ActiveRange.new('2013-10-20', '2013-10-29')
            vendor.add_active_range(range1).add_active_range(range2)
            expect(vendor.active_ranges.size).to eql(2)
          end

          it "should allow making and unmaking a vendor use locations" do
            vendor = Vendor.new(1, 'Gumby')
            expect(vendor.uses_locations?).to be_false
            vendor.make_restricted_by_locations
            expect(vendor.uses_locations?).to be_true
            vendor.make_unrestricted_by_locations
            expect(vendor.uses_locations?).to be_false
          end

          it "should allow adding locations" do
            vendor = Vendor.new(1, 'Gumby')
            vendor.add_location(Rack::AARM::DSL::Location.new('127.0.0.1'))
            vendor.add_location(Rack::AARM::DSL::Location.new('127.0.0.1'))
            expect(vendor.locations.size).to eql(2)
          end

          it "should respond correctly to various active_ranges" do
            vendor = Vendor.new(1, 'Gumby')
            range1 = ActiveRange.new('2013-10-01', '2013-10-10')
            range2 = ActiveRange.new('2013-10-20', '2013-10-29')
            vendor.add_active_range(range1).add_active_range(range2)
            (1..10).each do |dd|
              expect(vendor.active_on? "2013-10-%02d" % dd).to be_true
            end
            (11..19).each do |dd|
              expect(vendor.active_on? "2013-10-%02d" % dd).to be_false
            end
            (20..29).each do |dd|
              expect(vendor.active_on? "2013-10-%02d" % dd).to be_true
            end
          end

          it "should respond correctly when using locations and having locations" do
            vendor = Vendor.new(1, 'Gumby')
            vendor.make_restricted_by_locations
            range1 = ActiveRange.new('2013-10-01', '2013-10-10')
            range2 = ActiveRange.new('2013-10-20', '2013-10-29')
            vendor.add_location(Rack::AARM::DSL::Location.new('127.0.0.1').add_active_range(range1))
            vendor.add_location(Rack::AARM::DSL::Location.new('192.168.1.1').add_active_range(range2))
            expect(vendor.allowed_from?('10.0.0.1', '2013-10-01')).to be_false
            (1..10).each do |dd|
              expect(vendor.allowed_from?('127.0.0.1', "2013-10-%02d" % dd)).to be_true
              expect(vendor.allowed_from?('192.168.1.1', "2013-10-%02d" % dd)).to be_false
            end
            (11..19).each do |dd|
              expect(vendor.allowed_from?('127.0.0.1', "2013-10-%02d" % dd)).to be_false
              expect(vendor.allowed_from?('192.168.1.1', "2013-10-%02d" % dd)).to be_false
            end
            (20..29).each do |dd|
              expect(vendor.allowed_from?('127.0.0.1', "2013-10-%02d" % dd)).to be_false
              expect(vendor.allowed_from?('192.168.1.1', "2013-10-%02d" % dd)).to be_true
            end
          end

          it "should respond correctly when using the whizz bang test" do

            # Create some reources
            resources = Resources.new
            resource = Resource.new(1, 'billings.active', '/billings/api/v1')
            resource.add_suffix(Regexp.new('^\/banks$'))
            .add_verb('GET').add_active_range(ActiveRange.for_all_time).back_to_suffix
            .add_verb('POST').add_active_range(ActiveRange.for_all_time).back_to_suffix
            .add_verb('HEAD').add_active_range(ActiveRange.for_all_time).back_to_suffix
            resource.add_suffix(Regexp.new('^\/banks/[\d]+$'))
            .add_verb('GET').add_active_range(ActiveRange.for_all_time).back_to_suffix
            .add_verb('PUT').add_active_range(ActiveRange.for_all_time).back_to_suffix
            .add_verb('DELETE').add_active_range(ActiveRange.for_all_time).back_to_suffix
            resources.add(resource)
            all_past_to_20131001 = ActiveRange.new(ActiveRange.all_past, DateTime.new(2013, 10, 1))
            from_20131003_on = ActiveRange.new(DateTime.new(2013, 10, 3), ActiveRange.all_future)
            resource = Resource.new(2, 'billings.with.missing.date', '/billings/api/v2')
            resource.add_suffix(Regexp.new('^\/banks$'))
            .add_verb('GET').add_active_range(all_past_to_20131001).add_active_range(from_20131003_on).back_to_suffix
            .add_verb('POST').add_active_range(all_past_to_20131001).add_active_range(from_20131003_on).back_to_suffix
            .add_verb('HEAD').add_active_range(all_past_to_20131001).add_active_range(from_20131003_on).back_to_suffix
            resource.add_suffix(Regexp.new('^\/banks/[\d]+$'))
            .add_verb('GET').add_active_range(all_past_to_20131001).add_active_range(from_20131003_on).back_to_suffix
            .add_verb('PUT').add_active_range(all_past_to_20131001).add_active_range(from_20131003_on).back_to_suffix
            .add_verb('DELETE').add_active_range(all_past_to_20131001).add_active_range(from_20131003_on).back_to_suffix
            resources.add(resource)

            # Create a vendor
            vendor = Vendor.new(1, 'vendor1')
            .add_key(ActiveRange.for_all_time, "QOYNT/+GeMBQJzX+QSBuEA==", "MpzZMi+Aug6m/vd5VYdHrA==")
            .add_active_range(ActiveRange.for_all_time)
            .make_restricted_by_locations
            .add_location(Location.new('127.0.0.1').add_active_range(ActiveRange.for_all_time))
            .add_role('default', 'vendor1_default', '1f6edad466a632cb0c91fdc9c500b437').add_active_range(ActiveRange.for_all_time).add_rights(%w(GET), [1]).back_to_vendor
            .add_role('admin', 'vendor1_admin', 'b616111a3c791f223b89957e72859ad2').add_active_range(ActiveRange.for_all_time).add_rights(%w(GET POST PUT DELETE), [1, 2]).back_to_vendor

            # And test them
            expect(vendor.can_access?(resources, {
                                          :path => '/billings/api/v1/banks/123456',
                                          :via => 'GET',
                                          :on => '2013-10-14 12:35:56',
                                          :role => 'admin',
                                          :pass => 'b616111a3c791f223b89957e72859ad2',
                                          :ipv4 => '127.0.0.1'
                                      })).to be_true
            expect(vendor.can_access?(resources, {
                                          path: '/billings/api/v3/banks/123456',
                                          via: 'GET',
                                          on: '2013-10-14 12:35:56',
                                          role: 'admin',
                                          pass: 'b616111a3c791f223b89957e72859ad2',
                                          ipv4: '127.0.0.1'
                                      })).to be_false
          end

        end

      end
    end
  end
end
