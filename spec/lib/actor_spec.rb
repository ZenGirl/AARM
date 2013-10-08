require 'spec_helper'
require 'rspec'
require 'rack'
require 'rack/test'
require 'json'

require 'aarm'
require 'rack/aarm/api_key'

describe Rack::AARM do

  describe Rack::AARM::Actor do

    # -----------------------------------------------------------------------
    # Standard headers
    # -----------------------------------------------------------------------
    AUTHORISATION_HEADER = 'Authorisation'
    CONTENT_TYPE = 'CONTENT_TYPE'
    CONTENT_LENGTH = 'CONTENT_LENGTH'
    FORM_DATA = 'multipart/form-data'

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
    MESSAGE2_BAD_LOCATION = 'API calls require an active location header such as X-Real-IP, HTP_X_Real_IP or REMOTE_ADDR'

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
    $stderr.sync = true
    $stdout.sync = true

    # -----------------------------------------------------------------------
    # Before everything...
    # -----------------------------------------------------------------------
    before do
      # ---------------------------------------------------------------------
      # Arbitrarily set test mode
      # ---------------------------------------------------------------------
      Rack::AARM::Configuration.environment = :test
      # ---------------------------------------------------------------------
      # Get logger and messages
      # ---------------------------------------------------------------------
      @logger = Rack::AARM::Configuration.logger
      @logger.datetime_format = '%Y-%m-%d %H:%M:%S'
      @logger.formatter = proc do |severity, datetime, progname, msg|
        "                #{datetime.utc}: [#{severity.ljust(8)}] #{msg}\n"
      end
      @messages = Rack::AARM::Actor.messages
      # ---------------------------------------------------------------------
      # Configure some vendors
      # ---------------------------------------------------------------------
      @vendors = [
          {name: 'vendor1', api_key: 'VENDOR_1', api_secret: VALID_API_SECRET, active: true},
          {name: 'vendor2', api_key: 'VENDOR_2', api_secret: 'API_SECRET_2', active: false},
          {name: 'vendor3', api_key: 'VENDOR_3', api_secret: 'API_SECRET_3', active: true, use_locations: true},
          {name: 'vendor4', api_key: 'VENDOR_4', api_secret: 'API_SECRET_4', active: false, use_locations: true}
      ]
      Rack::AARM::Configuration.vendors = @vendors
      @locations = [
          {ipv4: '127.0.0.1', active: true, vendor_id: 'vendor3'},
      ]
      Rack::AARM::Configuration.locations = @locations
      @resources = [

      ]
      @config = {
          vendors: [
              {
                  name: 'vendor1',
                  display_name: 'Vendor #1',
                  keys: [
                      {from_date: nil, to_date: nil, api_key: 'VENDOR_1', api_secret: 'API_SECRET_1'}
                  ],
                  use_locations: false,
                  uses_external_auth: false, external_auth_route: '', external_party_id: '',
                  active: [{from_date: nil, to_date: nil}],
                  locations: [
                      {ipv4: '127.0.0.1', active: [{from_date: nil, to_date: nil}]}
                  ],
                  groups: [
                      {name: 'default', rights: [
                          {from_date: nil, to_date: nil, crud: '_R__'}
                      ]},
                      {name: 'IT', rights: [
                          {from_date: nil, to_date: nil, crud: 'CRUD'}
                      ]}
                  ]
              }
          ]
      }
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
          validate_code_and_messages(response, item[:code], @messages[item[:code]], MESSAGE2_INVALID_HEADER)
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
        validate_code_and_messages(response, '007', @messages['007'], MESSAGE2_BAD_VENDOR)
      end

    end

    # -----------------------------------------------------------------------
    # Valid key but vendor inactive
    # -----------------------------------------------------------------------
    context "incoming request has a valid key but the vendor is inactive" do

      it "has a known API-KEY but is not active" do
        request = Rack::MockRequest.new(Rack::AARM::Actor.new(plain))
        response = request.get('/', {AUTHORISATION_HEADER => "VENDOR_2:IRRELEVANT_TO_THIS_TEST"})
        response.status.should eq(401)
        validate_code_and_messages(response, '008', @messages['008'], MESSAGE2_BAD_VENDOR)
      end

    end

    # -----------------------------------------------------------------------
    # Has locations that need testing
    # -----------------------------------------------------------------------
    context "has a known API-KEY and is active, but uses locations and the remote is not allowed" do

        it "Has no headers set" do
          #TODO Hmm. This will be caught by prior tests...
        end

        it "And has various headers set" do
          # NGinx sends X-Real-IP
          # Apache can send HTTP_X_Real_IP and/or REMOTE_ADDR
          %w(X-Real-IP HTTP_X_Real_IP REMOTE_ADDR).each do |header|
            request = Rack::MockRequest.new(Rack::AARM::Actor.new(plain))
            response = request.get('/', {
                AUTHORISATION_HEADER => "VENDOR_3:IRRELEVANT_TO_THIS_TEST",
                header => '192.168.1.1'
            })
            response.status.should eq(401)
            validate_code_and_messages(response, '009', @messages['009'], MESSAGE2_BAD_LOCATION)
          end
        end

      end

    # -----------------------------------------------------------------------
    # Test query string and body data fr various verbs
    # -----------------------------------------------------------------------
    context "Provided QueryString and/or body params did not decrypt properly" do

      context "POST" do

        it "Is an invalid post" do
          query_params = {}
          body_params = {
              :a => 'params',
              :e => 'some',
              :c => 'these'
          }
          all_params = {}.merge(query_params).merge(body_params)
          cipher = get_cipher_for(VALID_API_SECRET)
          json_string = Hash[all_params.sort].to_json
          encoded, iv = cipher.encrypt_this(json_string)
          headers = {
              AUTHORISATION_HEADER => "VENDOR_1:#{encoded}_#{iv}",
              CONTENT_TYPE => FORM_DATA,
              CONTENT_LENGTH => json_string.size,
              :input => StringIO.new(all_params.to_json)
          }
          request = Rack::MockRequest.new(Rack::AARM::Actor.new(plain))
          # Here's where we're adding extra params that haven't been encrypted
          response = request.post("/?foo=bar", headers)
          response.status.should eq(401)
          @logger.debug "Body: [#{response.body}]"
        end

        it "Is a valid post" do
          query_params = {}
          body_params = {
              :a => 'params',
              :e => 'some',
              :c => 'these'
          }
          all_params = {}.merge(query_params).merge(body_params)
          cipher = get_cipher_for(VALID_API_SECRET)
          json_string = Hash[all_params.sort].to_json
          encoded, iv = cipher.encrypt_this(json_string)
          headers = {
              AUTHORISATION_HEADER => "VENDOR_1:#{encoded}_#{iv}",
              CONTENT_TYPE => FORM_DATA,
              CONTENT_LENGTH => json_string.size,
              :input => StringIO.new(all_params.to_json)
          }
          request = Rack::MockRequest.new(Rack::AARM::Actor.new(plain))
          response = request.post("/", headers)
          response.status.should eq(200)
          @logger.debug "Body: [#{response.body}]"
        end

        it "Is a post with extra query-string parameters" do
          query_params = {
              :b => 'these',
              :d => 'are',
              :f => 'hello'
          }
          body_params = {
              :a => 'params',
              :e => 'some',
              :c => 'these'
          }
          all_params = {}.merge(query_params).merge(body_params)
          cipher = get_cipher_for(VALID_API_SECRET)
          json_string = Hash[all_params.sort].to_json
          encoded, iv = cipher.encrypt_this(json_string)
          headers = {
              AUTHORISATION_HEADER => "VENDOR_1:#{encoded}_#{iv}",
              CONTENT_TYPE => FORM_DATA,
              CONTENT_LENGTH => json_string.size,
              :input => StringIO.new(all_params.to_json)
          }
          request = Rack::MockRequest.new(Rack::AARM::Actor.new(plain))
          response = request.post("/", headers)
          response.status.should eq(200)
          @logger.debug "Body: [#{response.body}]"
        end

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


















