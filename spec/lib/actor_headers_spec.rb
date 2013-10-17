require 'spec_helper'
require 'rspec'
require 'rack'
require 'rack/test'
require 'json'

# Pull in all requirements
require 'aarm'

describe Rack::AARM do

  describe Rack::AARM::Actor do

    AUTHORISATION_HEADER = 'Authorisation'
    CONTENT_TYPE = 'CONTENT_TYPE'
    CONTENT_LENGTH = 'CONTENT_LENGTH'
    FORM_DATA = 'multipart/form-data'

    let(:actor_messages) { Rack::AARM::Actor.messages }
    let(:all_time) { Rack::AARM::DSL::ActiveRange.for_all_time }

    let(:test_date) { Date.today }
    let(:yesterday) { test_date.prev_day.to_datetime }
    let(:tomorrow) { test_date.next_day.to_datetime }
    let(:before_today) { Rack::AARM::DSL::ActiveRange.new(Rack::AARM::DSL::ActiveRange.all_past, yesterday) }
    let(:after_today) { Rack::AARM::DSL::ActiveRange.new(tomorrow, Rack::AARM::DSL::ActiveRange.all_future) }
    let(:all_time) { Rack::AARM::DSL::ActiveRange.for_all_time }

    let(:plain) do
      lambda { |env| [200, {}, []] }
    end
    let(:std_request) do
      Rack::MockRequest.new(Rack::AARM::Actor.new(plain))
    end

    # -----------------------------------------------------------------------
    # Before everything...
    # -----------------------------------------------------------------------
    before do
      Rack::AARM::Configuration.environment = :test
      Rack::AARM::Configuration.logger = ::Logger.new(STDERR)
      @logger = Rack::AARM::Configuration.logger
      @logger.level = ::Logger::DEBUG
      @logger.datetime_format = '%Y-%m-%d %H:%M:%S'
      @logger.formatter = proc do |severity, datetime, progname, msg|
        "                #{datetime.utc}: [#{severity.ljust(8)}] #{msg}\n"
      end
    end

    # -----------------------------------------------------------------------
    # Request has bad or missing Authorisation header
    # -----------------------------------------------------------------------
    context "incoming request has no or badly formatted Authorization header" do

      before do
        # Add two dummy vendors
        vendors = Rack::AARM::DSL::Vendors.new
        key, secret = Rack::AARM::APIKey.get_new_key_pair
        vendors.add Rack::AARM::DSL::Vendor.new(1, 'vendor1').add_key(all_time, key, secret)
        key, secret = Rack::AARM::APIKey.get_new_key_pair
        vendors.add Rack::AARM::DSL::Vendor.new(2, 'vendor2').add_key(all_time, key, secret)
        Rack::AARM::Configuration.vendors = vendors
        # Add a dummy resource
        resources = Rack::AARM::DSL::Resources.new
        resources.add Rack::AARM::DSL::Resource.new(1, 'billings.active', '/billings/api/v1')
        Rack::AARM::Configuration.resources = resources
      end

      # Do a series of header tests
      [
          {msg: 'auth_header_missing', code: '001', headers: {}},
          {msg: 'auth_header_empty', code: '003', headers: {AUTHORISATION_HEADER => ''}},
          {msg: 'auth_header_missing_key_missing_signature', code: '004', headers: {AUTHORISATION_HEADER => ':'}},
          {msg: 'auth_header_good_key_missing_signature', code: '006', headers: {AUTHORISATION_HEADER => "MAW7etb4aZ53XUsx3Uwl6Q=="}},
          {msg: 'auth_header_bad_key_missing_signature', code: '006', headers: {AUTHORISATION_HEADER => "INVALID_KEY:"}},
          {msg: 'auth_header_missing_key_good_signature', code: '005', headers: {AUTHORISATION_HEADER => ":EX4dweK/pxqGnjDlRm0O0A=="}},
          {msg: 'auth_header_missing_key_bad_signature', code: '005', headers: {AUTHORISATION_HEADER => ":INVALID_SIGNATURE"}}
      ].each do |item|
        it item[:msg] do
          response = std_request.get('/', item[:headers])
          response.status.should eq(401)
          parsed = JSON.parse(response.body)
          expect(parsed['code']).to eq(item[:code])
          expect(parsed['messages'].size).to eq(2)
          expect(parsed['messages'][0]).to eq(actor_messages[item[:code]])
          expect(parsed['messages'][1]).to eq(Rack::AARM::Actor::MESSAGE2_INVALID_HEADER)
        end
      end
    end

    # ---------------------------------------------------------------------
    # Request has unknown API-KEY
    # ---------------------------------------------------------------------
    context "incoming request has invalid API-KEY" do

      it "has an unknown API-KEY" do
        # Add two dummy vendors
        vendors = Rack::AARM::DSL::Vendors.new
        key, secret = Rack::AARM::APIKey.get_new_key_pair
        vendors.add Rack::AARM::DSL::Vendor.new(1, 'vendor1').add_key(all_time, key, secret)
        key, secret = Rack::AARM::APIKey.get_new_key_pair
        vendors.add Rack::AARM::DSL::Vendor.new(2, 'vendor2').add_key(all_time, key, secret)
        Rack::AARM::Configuration.vendors = vendors
        # Add a dummy resource
        resources = Rack::AARM::DSL::Resources.new
        resources.add Rack::AARM::DSL::Resource.new(1, 'billings.active', '/billings/api/v1')
        Rack::AARM::Configuration.resources = resources

        # Do the test
        response = std_request.get('/', {AUTHORISATION_HEADER => "NOT_A_VALID_API_KEY:IRRELEVANT_TO_THIS_TEST"})
        response.status.should eq(401)
        parsed = JSON.parse(response.body)
        expect(parsed['code']).to eq('007')
        expect(parsed['messages'].size).to eq(2)
        expect(parsed['messages'][0]).to eq(actor_messages['007'])
        expect(parsed['messages'][1]).to eq(Rack::AARM::Actor::MESSAGE2_BAD_VENDOR)
      end

    end

    # -----------------------------------------------------------------------
    # Valid key but vendor inactive
    # -----------------------------------------------------------------------
    context "incoming request has a valid key but the vendor is inactive" do

      it "has a known API-KEY but is not active" do
        Rack::AARM::Configuration.test_date = test_date.to_datetime
        # Add two dummy vendors
        vendors = Rack::AARM::DSL::Vendors.new
        # First is only active from epoch to yesterday
        key1, secret1 = Rack::AARM::APIKey.get_new_key_pair
        vendors.add Rack::AARM::DSL::Vendor.new(1, 'vendor1').add_key(before_today, key1, secret1)
        # Second is valid across time
        key2, secret2 = Rack::AARM::APIKey.get_new_key_pair
        vendors.add Rack::AARM::DSL::Vendor.new(2, 'vendor2').add_key(all_time, key2, secret2)
        # Third is valid from tomorrow
        key3, secret3 = Rack::AARM::APIKey.get_new_key_pair
        vendors.add Rack::AARM::DSL::Vendor.new(3, 'vendor3').add_key(after_today, key3, secret3)
        Rack::AARM::Configuration.vendors = vendors
        # Add a dummy resource
        resources = Rack::AARM::DSL::Resources.new
        resources.add Rack::AARM::DSL::Resource.new(1, 'billings.active', '/billings/api/v1')
        Rack::AARM::Configuration.resources = resources

        # Do the test
        response = std_request.get('/', {AUTHORISATION_HEADER => "#{key3}:IRRELEVANT_TO_THIS_TEST"})
        response.status.should eq(401)
        parsed = JSON.parse(response.body)
        expect(parsed['code']).to eq('008')
        expect(parsed['messages'].size).to eq(2)
        expect(parsed['messages'][0]).to eq(actor_messages['008'])
        expect(parsed['messages'][1]).to eq(Rack::AARM::Actor::MESSAGE2_BAD_VENDOR)
      end

    end

    # -----------------------------------------------------------------------
    # Has locations that need testing
    # -----------------------------------------------------------------------
    context "has a known API-KEY and is active, but uses locations and the remote is not allowed" do

      it "on the testing date" do

        # Set testing_date
        test_date = Date.today
        yesterday = test_date.prev_day.to_datetime
        tomorrow = test_date.next_day.to_datetime
        Rack::AARM::Configuration.test_date = test_date.to_datetime
        # Set some active ranges
        before_today = Rack::AARM::DSL::ActiveRange.new(Rack::AARM::DSL::ActiveRange.all_past, yesterday)
        after_today = Rack::AARM::DSL::ActiveRange.new(tomorrow, Rack::AARM::DSL::ActiveRange.all_future)
        all_time = Rack::AARM::DSL::ActiveRange.for_all_time
        # Add two dummy vendors
        vendors = Rack::AARM::DSL::Vendors.new
        # First is only active from epoch to yesterday
        key1, secret1 = Rack::AARM::APIKey.get_new_key_pair
        vendors.add Rack::AARM::DSL::Vendor.new(1, 'vendor1').add_key(before_today, key1, secret1)
        # Second is valid across time
        key2, secret2 = Rack::AARM::APIKey.get_new_key_pair
        vendor2 = Rack::AARM::DSL::Vendor.new(2, 'vendor2')
        vendor2.add_key(all_time, key2, secret2)
        vendor2.make_restricted_by_locations
        vendor2.add_location(Rack::AARM::DSL::Location.new('127.0.0.1').add_active_range(all_time))
        vendor2.add_location(Rack::AARM::DSL::Location.new('192.168.3.129').add_active_range(before_today))
        vendors.add vendor2
        # Third is valid from tomorrow
        key3, secret3 = Rack::AARM::APIKey.get_new_key_pair
        vendors.add Rack::AARM::DSL::Vendor.new(3, 'vendor3').add_key(after_today, key3, secret3)
        Rack::AARM::Configuration.vendors = vendors
        # Add a dummy resource
        resources = Rack::AARM::DSL::Resources.new
        resources.add Rack::AARM::DSL::Resource.new(1, 'billings.active', '/billings/api/v1')
        Rack::AARM::Configuration.resources = resources

        # Do the test
        # NGinx sends X-Real-IP
        # Apache can send HTTP_X_Real_IP and/or REMOTE_ADDR
        %w(X-Real-IP HTTP_X_Real_IP REMOTE_ADDR).each do |header|
          response = std_request.get('/', {
              AUTHORISATION_HEADER => "#{key2}:IRRELEVANT_TO_THIS_TEST",
              header => '192.168.3.129'
          })
          response.status.should eq(401)
          parsed = JSON.parse(response.body)
          expect(parsed['code']).to eq('009')
          expect(parsed['messages'].size).to eq(2)
          expect(parsed['messages'][0]).to eq(actor_messages['009'])
          expect(parsed['messages'][1]).to eq(Rack::AARM::Actor::MESSAGE2_BAD_LOCATION)
        end
      end

    end

  end

end


















