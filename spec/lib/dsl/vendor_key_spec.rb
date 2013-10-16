require 'spec_helper'
require 'rspec'
require 'rack'
require 'rack/test'
require 'json'

require 'aarm'
require 'rack/aarm/dsl/vendor_key'

module Rack
  module AARM
    module DSL

      describe VendorKey do

        context "It passes basic tests" do

          it "should raise an error if passed invalid arguments" do
            range = ActiveRange.new('2013-10-01', '2013-10-10')
            expect { VendorKey.new(nil, nil, nil) }.to raise_error ArgumentError, Rack::AARM::DSL::Helpers::ARGUMENTS_BAD
            expect { VendorKey.new(range, nil, nil) }.to raise_error ArgumentError, Rack::AARM::DSL::Helpers::ARGUMENTS_BAD
            expect { VendorKey.new(range, '', nil) }.to raise_error ArgumentError, Rack::AARM::DSL::Helpers::ARGUMENTS_BAD
            expect { VendorKey.new(range, 'key', nil) }.to raise_error ArgumentError, Rack::AARM::DSL::Helpers::ARGUMENTS_BAD
            expect { VendorKey.new(range, 'key', '') }.to raise_error ArgumentError, Rack::AARM::DSL::Helpers::ARGUMENTS_BAD
            expect { VendorKey.new(range, 'key', 'spec') }.not_to raise_error
          end

        end

      end
    end
  end
end
