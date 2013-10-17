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
      # It can handle valid yml files
      # ---------------------------------------------------------------------
      #it "allows configuration from valid yml file" do
      #  Rack::AARM::Configuration.reset
      #  err_logger = Logger.new(STDERR)
      #  err_logger.level = ::Logger::DEBUG
      #  err_logger.datetime_format = '%Y-%m-%d %H:%M:%S'
      #  err_logger.formatter = proc do |severity, datetime, progname, msg|
      #    "#{datetime.utc}: [#{severity.ljust(8)}] #{msg}\n"
      #  end
      #  Rack::AARM::Configuration.logger = err_logger
      #  Rack::AARM::Configuration.environment = :test
      #  Rack::AARM::Configuration.configure_from(File.join(__dir__,'..','vendors.yml'))
      #  vendors = Rack::AARM::Configuration.vendors
      #  expect(vendors.size).to eql(2)
      #  expect(vendors[0][:name]).to eql('vendor1')
      #  expect(vendors[1][:name]).to eql('vendor2')
      #  Rack::AARM::Configuration.configure_from(File.join(__dir__,'..','resources.yml'))
      #  resources = Rack::AARM::Configuration.resources
      #  expect(resources.size).to eql(2)
      #  expect(resources[0][:name]).to eql('Billings Active')
      #  expect(resources[1][:name]).to eql('Billings In-Active')
      #end

    end

  end
end
