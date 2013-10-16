require 'spec_helper'
require 'rspec'
require 'factory_girl'

require_relative '../../lib/aarm'

FactoryGirl.find_definitions

describe 'Rack Middleware' do

  describe 'ResourceAudit' do

    context 'creating record' do
      #it 'creates 5 records' do
      #  audit = FactoryGirl.build(:resource_audit, vendor_name: 'LocalDirectories')
      #  p audit.vendor_name
      #end
    end

  end
end
