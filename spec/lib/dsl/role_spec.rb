require 'spec_helper'
require 'rspec'
require 'rack'
require 'rack/test'
require 'json'

require 'aarm'
require 'rack/aarm/dsl/role'

module Rack
  module AARM
    module DSL

      describe Role do

        context "It passes basic tests" do

          it "should raise an error if passed invalid arguments" do
            expect { Role.new(nil, nil, nil) }.to raise_error ArgumentError, Rack::AARM::DSL::Helpers::ARGUMENTS_BAD
            expect { Role.new('Gumby', nil, nil) }.to raise_error ArgumentError, Rack::AARM::DSL::Helpers::ARGUMENTS_BAD
            expect { Role.new('Gumby', '', nil) }.to raise_error ArgumentError, Rack::AARM::DSL::Helpers::ARGUMENTS_BAD
            expect { Role.new('Gumby', 'pass', nil) }.to raise_error ArgumentError, Rack::AARM::DSL::Helpers::ARGUMENTS_BAD
            expect { Role.new('Gumby', 'pass', '') }.to raise_error ArgumentError, Rack::AARM::DSL::Helpers::ARGUMENTS_BAD
            expect { Role.new('Gumby', 'pass', 'md5') }.not_to raise_error
          end

          it "should allow adding active ranges" do
            role = Role.new('Gumby', 'pass', 'md5')
            range1 = ActiveRange.new('2013-10-01', '2013-10-10')
            range2 = ActiveRange.new('2013-10-20', '2013-10-29')
            role.add_active_range(range1).add_active_range(range2)
            expect(role.active_ranges.size).to eql(2)
          end

          it "should raise errors if passed invalid rights" do
            role = Role.new('Gumby', 'pass', 'md5')
            expect { role.add_rights(nil, nil) }.to raise_error ArgumentError, Rack::AARM::DSL::Helpers::ARGUMENTS_BAD
            expect { role.add_rights('', nil) }.to raise_error ArgumentError, Rack::AARM::DSL::Helpers::ARGUMENTS_BAD
            expect { role.add_rights([], nil) }.to raise_error ArgumentError, Rack::AARM::DSL::Helpers::ARGUMENTS_BAD
            expect { role.add_rights([], [
                Resource.new(1,'',''),
                nil,
                ''
            ]) }.to raise_error ArgumentError, Rack::AARM::DSL::Helpers::ARGUMENTS_BAD
            expect { role.add_rights(%w(NOT REAL HTTP VERBS), nil) }.to raise_error ArgumentError, Rack::AARM::DSL::Helpers::ARGUMENTS_BAD
          end

          it "should respond correctly to various active_ranges" do
            role = Role.new('Gumby', 'pass', 'md5')
            range1 = ActiveRange.new('2013-10-01', '2013-10-10')
            range2 = ActiveRange.new('2013-10-20', '2013-10-29')
            role.add_active_range(range1).add_active_range(range2)
            (1..10).each do |dd|
              expect(role.active_on? "2013-10-%02d" % dd).to be_true
            end
            (11..19).each do |dd|
              expect(role.active_on? "2013-10-%02d" % dd).to be_false
            end
            (20..29).each do |dd|
              expect(role.active_on? "2013-10-%02d" % dd).to be_true
            end
          end

        end

      end
    end
  end
end
