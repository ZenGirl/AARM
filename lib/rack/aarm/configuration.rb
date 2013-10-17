require 'rack/auth/abstract/request'

module Rack
  module AARM
    class Configuration
      ENVIRONMENTS = [:test, :development, :production]
      @current_env = :production
      @vendors = []
      @resources = []
      @testing_date = DateTime.now

      ## -------------------------------------------------------------------------
      ## Configure through hash
      ## -------------------------------------------------------------------------
      #def self.configure(opts = {})
      #  opts.each { |k, v| CONF[k.to_sym] = v if CONF_KEYS.include? k.to_sym }
      #end

      # -------------------------------------------------------------------------
      # Configure through yaml file
      # This can be called multiple times
      # Example:
      #   Rack::AARM::configure_from('resources.yml')
      #   Rack::AARM::configure_from('vendors.yml')
      # Yields a merged @config
      # -------------------------------------------------------------------------
      #def self.configure_from(path_to_yaml_file)
      #  begin
      #    @config ||= {}
      #    yaml = YAML::load(IO.read(path_to_yaml_file))
      #    @config = @config.merge(yaml)
      #  rescue Errno::ENOENT
      #    @logger.warn "Rack::AARM::Configuration: YAML configuration file [#{path_to_yaml_file}] couldn't be found. Using defaults."
      #  rescue TypeError
      #    @logger.warn "Rack::AARM::Configuration: YAML configuration file [#{path_to_yaml_file}] contains invalid syntax. Using defaults."
      #  end
      #end

      def self.configuration_hash
        {
            vendors: @vendors,
            resources: @resources
        }
      end

      def self.vendors
        @vendors
      end

      def self.vendors=(v)
        @vendors = v
      end

      def self.resources
        @resources
      end

      def self.resources=(r)
        @resources = r
      end

      # ---------------------------------------------------------------------
      # Purely for testing
      def self.test_date
        @testing_date
      end

      def self.test_date=(d)
        @testing_date = d
      end
      # =====================================================================

      def self.reset
        @current_env = :production
        @vendors = []
        @resources = []
        @logger = ::Logger.new(STDERR)
      end

      def self.environment=(env)
        if ENVIRONMENTS.include? env
          @current_env = env
        else
          raise ArgumentError.new "Rack::AARM::Configuration: Invalid environment provided. Must be one of #{ENVIRONMENTS}"
        end
      end

      def self.environment
        @current_env
      end

      # -------------------------------------------------------------------------
      # Logger
      # -------------------------------------------------------------------------
      def self.logger=(logger)
        @logger = logger
      end

      def self.logger
        ensure_logger
      end

      def self.logger_level=(level)
        ensure_logger
        @logger.level = level
      end

      private

      def self.ensure_logger
        @logger ||= ::Logger.new(STDOUT)
      end

    end
  end
end