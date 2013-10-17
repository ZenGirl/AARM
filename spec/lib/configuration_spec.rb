require 'spec_helper'
require 'rspec'

require 'aarm'

describe Rack::AARM do

  describe Rack::AARM::Configuration do

    # -----------------------------------------------------------------------
    # Testing the configuration module works
    # -----------------------------------------------------------------------
    context 'valid configuration' do

      # ---------------------------------------------------------------------
      # Only allowed environments can be set
      # ---------------------------------------------------------------------
      it 'defaults to production' do
        Rack::AARM::Configuration.reset
        expect(Rack::AARM::Configuration.environment).to eq(:production)
      end

      it 'allows change to development' do
        Rack::AARM::Configuration.reset
        Rack::AARM::Configuration.environment = :development
        expect(Rack::AARM::Configuration.environment).to eq(:development)
      end

      it 'allows change to test' do
        Rack::AARM::Configuration.reset
        Rack::AARM::Configuration.environment = :test
        expect(Rack::AARM::Configuration.environment).to eq(:test)
      end

      it 'raises error if bad environment' do
        Rack::AARM::Configuration.reset
        expect{
            Rack::AARM::Configuration.environment = :not_a_real_environment
        }.to raise_error(
                 ArgumentError,
                 "Rack::AARM::Configuration: Invalid environment provided. Must be one of [:test, :development, :production]"
             )
      end

      # ---------------------------------------------------------------------
      # The internal logger is originally Logger.new(STDOUT)
      # ---------------------------------------------------------------------
      it 'allows logger change' do
        err_logger = Logger.new(STDERR)
        err_logger.datetime_format = '%Y-%m-%d %H:%M:%S'
        err_logger.formatter = proc do |severity, datetime, progname, msg|
          "#{datetime.utc}: [#{severity.ljust(8)}] #{msg}\n"
        end
        Rack::AARM::Configuration.logger = err_logger
        expect(
            Rack::AARM::Configuration.logger
        ).to eq(err_logger)
        Rack::AARM::Configuration.logger.debug "Debug message"
        Rack::AARM::Configuration.logger.info "Info message"
        Rack::AARM::Configuration.logger.warn "Warn message"
        Rack::AARM::Configuration.logger.error "Error message"
        Rack::AARM::Configuration.logger.fatal "Fatal message"
      end

      # ---------------------------------------------------------------------
      # It can dump and restore from json
      # ---------------------------------------------------------------------
      it "can dump and restore from json file" do
        resources = Rack::AARM::DSL::Resources.new

        resource = Rack::AARM::DSL::Resource.new(1, 'billings.active', '/billings/api/v1')
        resource.add_suffix(Regexp.new('^\/banks$'))
        .add_verb('GET').add_active_range(Rack::AARM::DSL::ActiveRange.for_all_time).back_to_suffix
        .add_verb('POST').add_active_range(Rack::AARM::DSL::ActiveRange.for_all_time).back_to_suffix
        .add_verb('HEAD').add_active_range(Rack::AARM::DSL::ActiveRange.for_all_time).back_to_suffix
        resource.add_suffix(Regexp.new('^\/banks/[\d]+$'))
        .add_verb('GET').add_active_range(Rack::AARM::DSL::ActiveRange.for_all_time).back_to_suffix
        .add_verb('PUT').add_active_range(Rack::AARM::DSL::ActiveRange.for_all_time).back_to_suffix
        .add_verb('DELETE').add_active_range(Rack::AARM::DSL::ActiveRange.for_all_time).back_to_suffix
        resources.add(resource)

        all_past_to_20131001 = Rack::AARM::DSL::ActiveRange.new(Rack::AARM::DSL::ActiveRange.all_past, DateTime.new(2013, 10, 1))
        from_20131003_on = Rack::AARM::DSL::ActiveRange.new(DateTime.new(2013, 10, 3), Rack::AARM::DSL::ActiveRange.all_future)

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

        Rack::AARM::Configuration.resources = resources

        vendors = Rack::AARM::DSL::Vendors.new

        vendor = Rack::AARM::DSL::Vendor.new(1, 'vendor1')
        .add_key(Rack::AARM::DSL::ActiveRange.for_all_time, "QOYNT/+GeMBQJzX+QSBuEA==", "MpzZMi+Aug6m/vd5VYdHrA==")
        .make_restricted_by_locations
        .add_location(Rack::AARM::DSL::Location.new('127.0.0.1').add_active_range(Rack::AARM::DSL::ActiveRange.for_all_time))
        .add_role('default', 'vendor1_default', '1f6edad466a632cb0c91fdc9c500b437').add_active_range(Rack::AARM::DSL::ActiveRange.for_all_time).add_rights(%w(GET), [1]).back_to_vendor
        .add_role('admin', 'vendor1_admin', 'b616111a3c791f223b89957e72859ad2').add_active_range(Rack::AARM::DSL::ActiveRange.for_all_time).add_rights(%w(GET POST PUT DELETE), [1, 2]).back_to_vendor

        vendors.add vendor

        vendor = Rack::AARM::DSL::Vendor.new(2, 'vendor2')
        .add_key(Rack::AARM::DSL::ActiveRange.new('2013-10-01', '2013-10-31'), "wBxPg1il07wNMdkClLWsqg==", "q9cqANbXvthP6ypSMwQ3ow==")
        .make_restricted_by_locations
        .add_location(Rack::AARM::DSL::Location.new('127.0.0.1').add_active_range(Rack::AARM::DSL::ActiveRange.new('2013-10-01', '2013-10-14')).add_active_range(Rack::AARM::DSL::ActiveRange.new('2013-10-21', '2013-10-31')))
        .add_location(Rack::AARM::DSL::Location.new('192.168.3.129').add_active_range(Rack::AARM::DSL::ActiveRange.new('2013-10-15', '2013-10-20')))
        .add_role('reader12', 'vendor2_reader', '632357780d36658bf7f302b1c29c1620').add_active_range(Rack::AARM::DSL::ActiveRange.for_all_time).add_rights(%w(GET), [1, 2]).back_to_vendor
        .add_role('author12', 'vendor2_author', '782c9b1f47709012c0797aadd11efdf4').add_active_range(Rack::AARM::DSL::ActiveRange.for_all_time).add_rights(%w(GET POST PUT), [1, 2]).back_to_vendor
        .add_role('editor2', 'vendor2_editor', 'fc730593435b207f1d9bf62e53361cf4').add_active_range(Rack::AARM::DSL::ActiveRange.for_all_time).add_rights(%w(GET POST PUT), [2]).back_to_vendor
        .add_role('owner12', 'vendor2_owner', 'd1c21ef0802ee1849e048124510295ca').add_active_range(Rack::AARM::DSL::ActiveRange.for_all_time).add_rights(%w(GET POST PUT DELETE), [1, 2]).back_to_vendor

        vendors.add vendor

        Rack::AARM::Configuration.vendors = vendors

        vendors_hash_1 = vendors.to_hash
        resources_hash_1 = resources.to_hash

        Rack::AARM::Configuration.dump_to_json_file('/tmp/config.json')
        Rack::AARM::Configuration.restore_from_json_file('/tmp/config.json')

        vendors_hash_2 = vendors.to_hash
        resources_hash_2 = resources.to_hash

        expect(JSON.generate(vendors_hash_1)).to eql(JSON.generate(vendors_hash_2))
        expect(JSON.generate(resources_hash_1)).to eql(JSON.generate(resources_hash_2))
      end

    end

  end
end
