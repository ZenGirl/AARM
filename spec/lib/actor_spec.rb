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
    REMOTE_ADDR = 'REMOTE_ADDR'

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
      @messages = Rack::AARM::Actor.messages
    end

    # -----------------------------------------------------------------------
    # Test query string and body data for various verbs
    # -----------------------------------------------------------------------
    context "Provided QueryString and/or body params did not decrypt properly" do

      before(:each) do
        # Set testing_date
        test_date = Date.today
        yesterday = test_date.prev_day.to_datetime
        tomorrow = test_date.next_day.to_datetime
        Rack::AARM::Configuration.test_date = test_date.to_datetime
        # Set some active ranges
        before_today = Rack::AARM::DSL::ActiveRange.new(Rack::AARM::DSL::ActiveRange.all_past, yesterday)
        after_today = Rack::AARM::DSL::ActiveRange.new(tomorrow, Rack::AARM::DSL::ActiveRange.all_future)
        all_time = Rack::AARM::DSL::ActiveRange.for_all_time

        # -------------------------------------------------------------------
        # Create resources
        # -------------------------------------------------------------------
        resources = Rack::AARM::DSL::Resources.new

        # Resource that is active for all time for all verbs
        resource = Rack::AARM::DSL::Resource.new(1, 'all', '/for_all_time')
        resource.add_suffix(Regexp.new('^\/res$'))
        .add_verb('GET').add_active_range(all_time).back_to_suffix
        .add_verb('POST').add_active_range(all_time).back_to_suffix
        .add_verb('HEAD').add_active_range(all_time).back_to_suffix
        resource.add_suffix(Regexp.new('^\/res/[\d]+$'))
        .add_verb('GET').add_active_range(all_time).back_to_suffix
        .add_verb('PUT').add_active_range(all_time).back_to_suffix
        .add_verb('DELETE').add_active_range(all_time).back_to_suffix
        resources.add resource

        # Resource that is active for epoch to yesterday for all verbs
        resource = Rack::AARM::DSL::Resource.new(2, 'epoch_to', '/epoch_to_yesterday')
        resource.add_suffix(Regexp.new('^\/res$'))
        .add_verb('GET').add_active_range(before_today).back_to_suffix
        .add_verb('POST').add_active_range(before_today).back_to_suffix
        .add_verb('HEAD').add_active_range(before_today).back_to_suffix
        resource.add_suffix(Regexp.new('^\/res/[\d]+$'))
        .add_verb('GET').add_active_range(before_today).back_to_suffix
        .add_verb('PUT').add_active_range(before_today).back_to_suffix
        .add_verb('DELETE').add_active_range(before_today).back_to_suffix
        resources.add resource

        # Resource that is active for tomorrow to 2100 for all verbs
        resource = Rack::AARM::DSL::Resource.new(3, 'tomorrow_til', '/til_end_of_time')
        resource.add_suffix(Regexp.new('^\/res$'))
        .add_verb('GET').add_active_range(after_today).back_to_suffix
        .add_verb('POST').add_active_range(after_today).back_to_suffix
        .add_verb('HEAD').add_active_range(after_today).back_to_suffix
        resource.add_suffix(Regexp.new('^\/res/[\d]+$'))
        .add_verb('GET').add_active_range(after_today).back_to_suffix
        .add_verb('PUT').add_active_range(after_today).back_to_suffix
        .add_verb('DELETE').add_active_range(after_today).back_to_suffix
        resources.add resource

        # Resource that is active for for various verbs and dates
        resource = Rack::AARM::DSL::Resource.new(4, 'mash', '/up')
        resource.add_suffix(Regexp.new('^\/res$'))
        .add_verb('GET').add_active_range(before_today).add_active_range(after_today).back_to_suffix
        resource.add_suffix(Regexp.new('^\/res/[\d]+$'))
        .add_verb('PUT').add_active_range(before_today).add_active_range(after_today).back_to_suffix
        resources.add resource

        Rack::AARM::Configuration.resources = resources


        # -------------------------------------------------------------------
        # Create vendors
        # -------------------------------------------------------------------
        vendors = Rack::AARM::DSL::Vendors.new
        # First is only active from epoch to yesterday
        key1, secret1 = Rack::AARM::APIKey.get_new_key_pair
        vendor1 = Rack::AARM::DSL::Vendor.new(1, 'vendor1').add_key(all_time, key1, secret1)
        vendor1.add_role('default', 'vendor1_default', '1f6edad466a632cb0c91fdc9c500b437').add_active_range(all_time).add_rights(%w(GET), [1])
        vendor1.add_role('admin', 'vendor1_admin', 'b616111a3c791f223b89957e72859ad2').add_active_range(all_time).add_rights(%w(GET POST PUT DELETE), [1, 2])
        vendors.add vendor1
        # Second is valid across time
        key2, secret2 = Rack::AARM::APIKey.get_new_key_pair
        vendor2 = Rack::AARM::DSL::Vendor.new(2, 'vendor2').add_key(all_time, key2, secret2)
        vendor2.add_role('default', 'vendor1_default', '1f6edad466a632cb0c91fdc9c500b437').add_active_range(before_today).add_rights(%w(GET), [1])
        vendor2.add_role('admin', 'vendor1_admin', 'b616111a3c791f223b89957e72859ad2').add_active_range(before_today).add_rights(%w(GET POST PUT DELETE), [1, 2])
        vendors.add vendor2
        # Third is valid from tomorrow
        key3, secret3 = Rack::AARM::APIKey.get_new_key_pair
        vendor3 = Rack::AARM::DSL::Vendor.new(3, 'vendor3').add_key(after_today, key3, secret3)
        vendor3.add_role('default', 'vendor1_default', '1f6edad466a632cb0c91fdc9c500b437').add_active_range(after_today).add_rights(%w(GET), [1])
        vendor3.add_role('admin', 'vendor1_admin', 'b616111a3c791f223b89957e72859ad2').add_active_range(after_today).add_rights(%w(GET POST PUT DELETE), [1, 2])
        vendors.add vendor3
        # Fourth has open slather
        key4, secret4 = Rack::AARM::APIKey.get_new_key_pair
        vendor4 = Rack::AARM::DSL::Vendor.new(3, 'vendor3').add_key(all_time, key4, secret4)
        vendor4.add_role('default', 'vendor1_default', '1f6edad466a632cb0c91fdc9c500b437').add_active_range(all_time).add_rights(%w(GET POST PUT DELETE HEAD), [1, 2])
        vendor4.add_role('admin', 'vendor1_admin', 'b616111a3c791f223b89957e72859ad2').add_active_range(all_time).add_rights(%w(GET POST PUT DELETE HEAD), [1, 2])
        vendors.add vendor4

        Rack::AARM::Configuration.vendors = vendors


        @vendor_1_key, @vendor_1_secret = key1, secret1
        @vendor_2_key, @vendor_2_secret = key2, secret2
        @vendor_3_key, @vendor_3_secret = key3, secret3
        @vendor_4_key, @vendor_4_secret = key4, secret4
      end

      context "GET" do

        it "and is valid and allowed" do
          query_params, body_params = {}, {}
          all_params = {}.merge(query_params).merge(body_params)
          json_string = Hash[all_params.sort].to_json
          encoded, iv = get_cipher_for(@vendor_4_secret).encrypt_this(json_string)
          response = std_request.get("/for_all_time/res", {
              AUTHORISATION_HEADER => "#{@vendor_4_key}:#{encoded}_#{iv}",
              REMOTE_ADDR => '127.0.0.1',
              CONTENT_LENGTH => json_string.size,
              :input => StringIO.new(all_params.to_json)
          })
          response.status.should eq(200)
          response = std_request.get("/for_all_time/res/12345", {
              AUTHORISATION_HEADER => "#{@vendor_4_key}:#{encoded}_#{iv}",
              REMOTE_ADDR => '127.0.0.1',
              CONTENT_LENGTH => json_string.size,
              :input => StringIO.new(all_params.to_json)
          })
          response.status.should eq(200)
        end

        it "should be denied access to disallowed resources" do
          query_params, body_params = {}, {}
          all_params = {}.merge(query_params).merge(body_params)
          json_string = Hash[all_params.sort].to_json
          encoded, iv = get_cipher_for(@vendor_4_secret).encrypt_this(json_string)
          response = std_request.get("/epoch_to_yesterday/res", {
              AUTHORISATION_HEADER => "#{@vendor_4_key}:#{encoded}_#{iv}",
              REMOTE_ADDR => '127.0.0.1',
              CONTENT_LENGTH => json_string.size,
              :input => StringIO.new(all_params.to_json)
          })
          response.status.should eq(403)
          response = std_request.get("/til_end_of_time/res", {
              AUTHORISATION_HEADER => "#{@vendor_4_key}:#{encoded}_#{iv}",
              REMOTE_ADDR => '127.0.0.1',
              CONTENT_LENGTH => json_string.size,
              :input => StringIO.new(all_params.to_json)
          })
          response.status.should eq(403)
        end

      end

      context "POST" do

        it "and is valid and allowed" do
          query_params, body_params = {}, {:a => 'params', :e => 'some', :c => 'these'}
          all_params = {}.merge(query_params).merge(body_params)
          json_string = Hash[all_params.sort].to_json
          encoded, iv = get_cipher_for(@vendor_4_secret).encrypt_this(json_string)
          response = std_request.post("/for_all_time/res", {
              AUTHORISATION_HEADER => "#{@vendor_4_key}:#{encoded}_#{iv}",
              REMOTE_ADDR => '127.0.0.1',
              CONTENT_LENGTH => json_string.size,
              :input => StringIO.new(all_params.to_json)
          })
          response.status.should eq(200)
          response = std_request.post("/for_all_time/res/12345", {
              AUTHORISATION_HEADER => "#{@vendor_4_key}:#{encoded}_#{iv}",
              REMOTE_ADDR => '127.0.0.1',
              CONTENT_LENGTH => json_string.size,
              :input => StringIO.new(all_params.to_json)
          })
          response.status.should eq(403)
        end

        it "should be denied access to disallowed resources" do
          query_params, body_params = {}, {:a => 'params', :e => 'some', :c => 'these'}
          all_params = {}.merge(query_params).merge(body_params)
          json_string = Hash[all_params.sort].to_json
          encoded, iv = get_cipher_for(@vendor_4_secret).encrypt_this(json_string)
          response = std_request.post("/epoch_to_yesterday/res", {
              AUTHORISATION_HEADER => "#{@vendor_4_key}:#{encoded}_#{iv}",
              REMOTE_ADDR => '127.0.0.1',
              CONTENT_LENGTH => json_string.size,
              :input => StringIO.new(all_params.to_json)
          })
          response.status.should eq(403)
          response = std_request.post("/til_end_of_time/res", {
              AUTHORISATION_HEADER => "#{@vendor_4_key}:#{encoded}_#{iv}",
              REMOTE_ADDR => '127.0.0.1',
              CONTENT_LENGTH => json_string.size,
              :input => StringIO.new(all_params.to_json)
          })
          response.status.should eq(403)
        end

      end

    end

  end

end


















