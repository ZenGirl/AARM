require 'rack/auth/abstract/request'

module Rack
  module AARM
    class Configuration
      ENVIRONMENTS = [:test, :development, :production]
      @current_env = :production

      ## -------------------------------------------------------------------------
      ## Configure through hash
      ## -------------------------------------------------------------------------
      #def self.configure(opts = {})
      #  opts.each { |k, v| CONF[k.to_sym] = v if CONF_KEYS.include? k.to_sym }
      #end
      #
      ## -------------------------------------------------------------------------
      ## Configure through yaml file
      ## -------------------------------------------------------------------------
      #def self.configure_with(path_to_yaml_file)
      #  begin
      #    config = YAML::load(IO.read(path_to_yaml_file))
      #  rescue Errno::ENOENT
      #    logger.warn "AARM: YAML configuration file couldn't be found. Using defaults."
      #  rescue Psych::SyntaxError
      #    logger.warn "AARM: YAML configuration file contains invalid syntax. Using defaults."
      #  end
      #  configure(config)
      #end

      def self.reset
        @current_env = :production
        @logger = ::Logger.new(STDOUT)
      end

      def self.environment=(env)
        if ENVIRONMENTS.include? env
          @current_env = env
        else
          raise ArgumentError.new "AARM: Invalid environment provided. Must be one of #{ENVIRONMENTS}"
        end
      end

      def self.environment
        @current_env
      end

      # -------------------------------------------------------------------------
      # Vendors for testing
      # -------------------------------------------------------------------------
      @vendors = []
      def self.vendors=(vendors)
        @vendors = vendors
      end
      def self.vendors
        @vendors
      end

      # -------------------------------------------------------------------------
      # locations for testing
      # -------------------------------------------------------------------------
      @locations = []
      def self.locations=(locations)
        @locations = locations
      end
      def self.locations
        @locations
      end

      # -------------------------------------------------------------------------
      # Logger
      # -------------------------------------------------------------------------
      def self.logger=(logger)
        @logger = logger
      end

      def self.logger
        @logger ||= ::Logger.new(STDOUT)
      end

      def self.logger_level=(level)
        @logger ||= ::Logger.new(STDOUT)
        @logger.level = level
      end

    end
  end
end