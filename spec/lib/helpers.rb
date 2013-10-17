module Helpers

  def with_call(req, path)
    request = Rack::MockRequest.new(Rack::AARM::Actor.new(req))
    response = request.get(path)
    yield(response) if block_given?
  end

  def validate_code_and_messages(res, code, message1, message2)
    parsed = JSON.parse(res.body)
    expect(parsed['code']).to eq(code)
    expect(parsed['messages'].size).to eq(2)
    expect(parsed['messages'][0]).to eq(message1)
    expect(parsed['messages'][1]).to eq(message2)
  end

  def all_crud_options
    %w(C___ CR__ CRU_ CRUD C_U_ C_UD C__D CR_D _R__ _RU_ _R_D _RUD __U_ __UD ___D)
  end

  def get_cipher_for(api_secret)
    cipher = Rack::AARM::APIKey.new(api_secret)
    cipher.logger.level = ::Logger::DEBUG
    cipher.logger.datetime_format = '%Y-%m-%d %H:%M:%S'
    cipher.logger.formatter = proc do |severity, datetime, progname, msg|
      "                #{datetime.utc}: [#{severity.ljust(8)}] #{msg}\n"
    end
    cipher
  end

  def configure_test_dates
    let(:test_date) { Date.today }
    @yesterday = test_date.prev_day.to_datetime
    @tomorrow = test_date.next_day.to_datetime
  end

  def assign_valid_configuration
    # -----------------------------------------------------------------
    # ActiveRanges
    # -----------------------------------------------------------------
    all_time = Rack::AARM::DSL::ActiveRange.for_all_time
    all_past = Rack::AARM::DSL::ActiveRange.all_past
    all_future = Rack::AARM::DSL::ActiveRange.all_future
    all_past_to_20131001 = Rack::AARM::DSL::ActiveRange.new(all_past, DateTime.new(2013, 10, 1))
    from_20131003_on = Rack::AARM::DSL::ActiveRange.new(DateTime.new(2013, 10, 3), all_future)
    october = Rack::AARM::DSL::ActiveRange.new('2013-10-01', '2013-10-31')
    october_1 = Rack::AARM::DSL::ActiveRange.new('2013-10-01', '2013-10-14')
    october_2 = Rack::AARM::DSL::ActiveRange.new('2013-10-21', '2013-10-31')
    october_3 = Rack::AARM::DSL::ActiveRange.new('2013-10-15', '2013-10-20')
    # -----------------------------------------------------------------
    # Resources
    # -----------------------------------------------------------------
    resources = Rack::AARM::DSL::Resources.new
    resource = Rack::AARM::DSL::Resource.new(1, 'billings.active', '/billings/api/v1')
    resource.add_suffix(Regexp.new('^\/banks$'))
    .add_verb('GET').add_active_range(all_time).back_to_suffix
    .add_verb('POST').add_active_range(all_time).back_to_suffix
    .add_verb('HEAD').add_active_range(all_time).back_to_suffix
    resource.add_suffix(Regexp.new('^\/banks/[\d]+$'))
    .add_verb('GET').add_active_range(all_time).back_to_suffix
    .add_verb('PUT').add_active_range(all_time).back_to_suffix
    .add_verb('DELETE').add_active_range(all_time).back_to_suffix
    resources.add(resource)
    resource = Rack::AARM::DSL::Resource.new(2, 'billings.with.missing.date', '/billings/api/v2')
    resource.add_suffix(Regexp.new('^\/banks$'))
    .add_verb('GET').add_active_range(all_past_to_20131001).add_active_range(from_20131003_on).back_to_suffix
    .add_verb('POST').add_active_range(all_past_to_20131001).add_active_range(from_20131003_on).back_to_suffix
    .add_verb('HEAD').add_active_range(all_past_to_20131001).add_active_range(from_20131003_on).back_to_suffix
    resource.add_suffix(Regexp.new('^\/banks/[\d]+$'))
    .add_verb('GET').add_active_range(all_past_to_20131001).add_active_range(from_20131003_on).back_to_suffix
    .add_verb('PUT').add_active_range(all_past_to_20131001).add_active_range(from_20131003_on).back_to_suffix
    .add_verb('DELETE').add_active_range(all_past_to_20131001).add_active_range(from_20131003_on).back_to_suffix
    resources.add(resource)
    # -----------------------------------------------------------------
    # Vendors
    # -----------------------------------------------------------------
    vendors = Rack::AARM::DSL::Vendors.new
    # Active for all time, restricted to localhost
    vendor = Rack::AARM::DSL::Vendor.new(1, 'vendor1')
    .add_key(all_time, "QOYNT/+GeMBQJzX+QSBuEA==", "MpzZMi+Aug6m/vd5VYdHrA==")
    .add_active_range(all_time)
    .make_restricted_by_locations
    .add_location(Rack::AARM::DSL::Location.new('127.0.0.1').add_active_range(all_time))
    .add_role('default', 'vendor1_default', '1f6edad466a632cb0c91fdc9c500b437').add_active_range(all_time).add_rights(%w(GET), [1]).back_to_vendor
    .add_role('admin', 'vendor1_admin', 'b616111a3c791f223b89957e72859ad2').add_active_range(all_time).add_rights(%w(GET POST PUT DELETE), [1, 2]).back_to_vendor
    vendors.add vendor
    # Active for October 2013, restricted to localhost from 1..14,21..31 and 192.168.3.129 from 15..20
    vendor = Rack::AARM::DSL::Vendor.new(2, 'vendor2')
    .add_key(october, "wBxPg1il07wNMdkClLWsqg==", "q9cqANbXvthP6ypSMwQ3ow==")
    .add_active_range(october)
    .make_restricted_by_locations
    .add_location(Rack::AARM::DSL::Location.new('127.0.0.1').add_active_range(october_1).add_active_range(october_2))
    .add_location(Rack::AARM::DSL::Location.new('192.168.3.129').add_active_range(october_3))
    .add_role('reader12', 'vendor2_reader', '632357780d36658bf7f302b1c29c1620').add_active_range(all_time).add_rights(%w(GET), [1, 2]).back_to_vendor
    .add_role('author12', 'vendor2_author', '782c9b1f47709012c0797aadd11efdf4').add_active_range(all_time).add_rights(%w(GET POST PUT), [1, 2]).back_to_vendor
    .add_role('editor2', 'vendor2_editor', 'fc730593435b207f1d9bf62e53361cf4').add_active_range(all_time).add_rights(%w(GET POST PUT), [2]).back_to_vendor
    .add_role('owner12', 'vendor2_owner', 'd1c21ef0802ee1849e048124510295ca').add_active_range(all_time).add_rights(%w(GET POST PUT DELETE), [1, 2]).back_to_vendor
    vendors.add vendor
    # Inactive vendor
    # -----------------------------------------------------------------
    # And push it into config
    # -----------------------------------------------------------------
    Rack::AARM::Configuration.reset
    Rack::AARM::Configuration.vendors = vendors
    Rack::AARM::Configuration.resources = resources
    #ap Rack::AARM::Configuration.configuration_hash

    Rack::AARM::Configuration.logger = ::Logger.new(STDERR)
    Rack::AARM::Configuration.logger_level = ::Logger::DEBUG
    @logger = Rack::AARM::Configuration.logger
    @logger.datetime_format = '%Y-%m-%d %H:%M:%S'
    @logger.formatter = proc do |severity, datetime, progname, msg|
      "                #{datetime.utc}: [#{severity.ljust(8)}] #{msg}\n"
    end

  end

end