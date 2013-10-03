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
        expect(
            Rack::AARM::Configuration.environment
        ).to eq(:production)
      end

      it 'allows change to development' do
        Rack::AARM::Configuration.reset
        Rack::AARM::Configuration.environment = :development
        expect(
            Rack::AARM::Configuration.environment
        ).to eq(:development)
      end

      it 'allows change to test' do
        Rack::AARM::Configuration.reset
        Rack::AARM::Configuration.environment = :test
        expect(
            Rack::AARM::Configuration.environment
        ).to eq(:test)
      end

      it 'raises error if bad environment' do
        Rack::AARM::Configuration.reset
        expect{
            Rack::AARM::Configuration.environment = :not_a_real_environment
        }.to raise_error(
                 ArgumentError,
                 "AARM: Invalid environment provided. Must be one of [:test, :development, :production]"
             )
      end

      # ---------------------------------------------------------------------
      # The internal logger is originally Logger.new(STDOUT)
      # ---------------------------------------------------------------------
      it 'allows logger change' do
        err_logger = Logger.new(STDERR)
        Rack::AARM::Configuration.logger = err_logger
        expect(
            Rack::AARM::Configuration.logger
        ).to eq(err_logger)
        Rack::AARM::Configuration.logger.info "Working with logger"
      end

    end

  end
end
