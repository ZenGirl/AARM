require 'spec_helper'
require 'rspec'
require 'rack'
require 'rack/test'
require 'json'

require 'aarm'

describe Rack::AARM do

  describe Rack::AARM::Actor do

    # -----------------------------------------------------------------------
    # Authorisation header
    # -----------------------------------------------------------------------
    AUTHORISATION_HEADER = 'Authorisation'

    # -----------------------------------------------------------------------
    # Generate KEYS and Signatures
    # -----------------------------------------------------------------------
    VALID_API_KEY = 'HruYu1fWDENhOQyaIOPH4/P21Ik='
    INVALID_API_KEY = 'BAD-KEY'
    VALID_API_SECRET = 'NXiz6PpL0z5CuzCETekuTw=='
    INVALID_API_SECRET = 'BAD-SECRET'
    VALID_SIGNATURE = 'hello world'
    INVALID_SIGNATURE = 'hello world'

    # -----------------------------------------------------------------------
    # Standard second messages
    # -----------------------------------------------------------------------
    MESSAGE2_INVALID_HEADER = 'API calls must have an Authorisation header'
    MESSAGE2_BAD_VENDOR = 'API calls require an active vendor key'

    # -----------------------------------------------------------------------
    # Standard call
    # -----------------------------------------------------------------------
    let(:plain) do
      lambda { |env| [200, {}, []] }
    end

    # -----------------------------------------------------------------------
    # Configure logging if desired
    # -----------------------------------------------------------------------
    Rack::AARM::Configuration.logger = ::Logger.new(STDERR)
    Rack::AARM::Configuration.logger_level = ::Logger::DEBUG
    Rack::AARM::Configuration.environment = :test

    # -----------------------------------------------------------------------
    # Before everything...
    # -----------------------------------------------------------------------
    before do
      @logger = Rack::AARM::Configuration.logger
      @messages = Rack::AARM::Actor.messages
      # ---------------------------------------------------------------------
      # Configure some vendors
      # ---------------------------------------------------------------------
      @vendors = [
          {name: 'vendor1', api_key: 'VENDOR_1', api_secret: 'API_SECRET_1', active: true},
          {name: 'vendor2', api_key: 'VENDOR_2', api_secret: 'API_SECRET_2', active: false},
          {name: 'vendor3', api_key: 'VENDOR_3', api_secret: 'API_SECRET_3', active: true, use_locations: true},
          {name: 'vendor4', api_key: 'VENDOR_4', api_secret: 'API_SECRET_4', active: false, use_locations: true}
      ]
      Rack::AARM::Configuration.vendors = @vendors
      @locations = [
          {ipv4: '127.0.0.1', active: true, vendor_id: 'vendor3'},
      ]
      Rack::AARM::Configuration.locations = @locations
    end

    # -----------------------------------------------------------------------
    # Request has bad or missing Authorisation header
    # -----------------------------------------------------------------------
    context "incoming request has no or badly formatted Authorization header" do

      [
          {msg: 'auth_header_missing', code: '001', headers: {}},
          {msg: 'auth_header_empty', code: '003', headers: {AUTHORISATION_HEADER => ''}},
          {msg: 'auth_header_missing_key_missing_signature', code: '004', headers: {AUTHORISATION_HEADER => ':'}},
          {msg: 'auth_header_good_key_missing_signature', code: '006', headers: {AUTHORISATION_HEADER => "#{VALID_API_KEY}:"}},
          {msg: 'auth_header_bad_key_missing_signature', code: '006', headers: {AUTHORISATION_HEADER => "#{INVALID_API_KEY}:"}},
          {msg: 'auth_header_missing_key_good_signature', code: '005', headers: {AUTHORISATION_HEADER => ":#{VALID_SIGNATURE}"}},
          {msg: 'auth_header_missing_key_bad_signature', code: '005', headers: {AUTHORISATION_HEADER => ":#{INVALID_SIGNATURE}"}}
      ].each do |item|
        it item[:msg] do
          request = Rack::MockRequest.new(Rack::AARM::Actor.new(plain))
          response = request.get('/', item[:headers])
          response.status.should eq(401)
          parsed = JSON.parse(response.body)
          expect(parsed['code']).to eq(item[:code])
          expect(parsed['messages'].size).to eq(2)
          expect(parsed['messages'][0]).to eq(@messages[item[:code]])
          expect(parsed['messages'][1]).to eq(MESSAGE2_INVALID_HEADER)
        end
      end
    end

    # ---------------------------------------------------------------------
    # Request has unknown API-KEY
    # ---------------------------------------------------------------------
    context "incoming request has invalid API-KEY" do

      it "has an unknown API-KEY" do
        request = Rack::MockRequest.new(Rack::AARM::Actor.new(plain))
        response = request.get('/', {AUTHORISATION_HEADER => "NOT_A_VALID_API_KEY:IRRELEVANT_TO_THIS_TEST"})
        response.status.should eq(401)
        parsed = JSON.parse(response.body)
        expect(parsed['code']).to eq('007')
        expect(parsed['messages'].size).to eq(2)
        expect(parsed['messages'][0]).to eq(@messages['007'])
        expect(parsed['messages'][1]).to eq(MESSAGE2_BAD_VENDOR)
      end

    end

    context "incoming request has a valid key but the vendor is inactive" do

      it "has a known API-KEY but is not active" do
        request = Rack::MockRequest.new(Rack::AARM::Actor.new(plain))
        response = request.get('/', {AUTHORISATION_HEADER => "VENDOR_2:IRRELEVANT_TO_THIS_TEST"})
        response.status.should eq(401)
        parsed = JSON.parse(response.body)
        expect(parsed['code']).to eq('008')
        expect(parsed['messages'].size).to eq(2)
        expect(parsed['messages'][0]).to eq(@messages['008'])
        expect(parsed['messages'][1]).to eq(MESSAGE2_BAD_VENDOR)
      end

      it "has a known API-KEY and is active, but uses locations and the remote is not allowed" do
        request = Rack::MockRequest.new(Rack::AARM::Actor.new(plain))
        response = request.get('/', {AUTHORISATION_HEADER => "VENDOR_3:IRRELEVANT_TO_THIS_TEST"})
        response.status.should eq(401)
        parsed = JSON.parse(response.body)
        expect(parsed['code']).to eq('009')
        expect(parsed['messages'].size).to eq(2)
        expect(parsed['messages'][0]).to eq(@messages['009'])
        expect(parsed['messages'][1]).to eq(MESSAGE2_BAD_VENDOR)
      end

    end

    context "incoming request denied by vendor" do

    end

    context "incoming request denied by resource group" do

      before(:all) do
        #@resources = []
        #@resource_groups = []
        #%w(C___ CR__ CRU_ CRUD C_U_ C_UD C__D CR_D _R__ _RU_ _R_D _RUD __U_ __UD ___D).each_with_index do |crud_version, index|
        #  [true, false].each do |tf|
        #    name = "group_#{index}_#{tf}"
        #    @resource_groups << {id: name, name: name, CRUD: crud_version, active: tf}
        #    [
        #        {verb: 'GET', route: "/api/v1/#{name}", active: true, group_id: name},
        #        {verb: 'GET', route: "/api/v1/#{name}/:id", active: true, group_id: name},
        #        {verb: 'POST', route: "/api/v1/#{name}", active: true, group_id: name},
        #        {verb: 'PUT', route: "/api/v1/#{name}/:id", active: true, group_id: name},
        #        {verb: 'DELETE', route: "/api/v1/#{name}/:id", active: true, group_id: name},
        #    ].each do |r|
        #      @resources << r
        #    end
        #  end
        #end
      end

    end

  end

end


















