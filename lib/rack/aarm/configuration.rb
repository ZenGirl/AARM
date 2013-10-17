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
      # Dump and restore
      # -------------------------------------------------------------------------
      def self.dump_to_json_file(filename)
        json = JSON.pretty_generate({
                                        vendors: @vendors.to_hash,
                                        resources: @resources.to_hash
                                    })
        ::File.open(filename, 'w') { |f| f.write(json) }
      rescue Exception => e
        @logger.error "Rack::AARM::Configuration: Unable to dump configuration to file [#{filename}]\nException: #{e}\n#{e.backtrace.join('\n')}"
      end

      def self.restore_from_json(json)
        config = JSON.parse(json)
        # Config vendors
        vendors = Rack::AARM::DSL::Vendors.new
        config['vendors'].each do |v|
          vendor = Rack::AARM::DSL::Vendor.new(v['id'], v['name'])
          v['vendor_keys'].each do |vk|
            vendor.add_key(Rack::AARM::DSL::ActiveRange.new(vk['active_range']['from_date'], vk['active_range']['to_date']), vk['key'], vk['secret'])
            vendor.make_restricted_by_locations if v['use_locations']
            v['locations'].each do |l|
              location = Rack::AARM::DSL::Location.new(l['ipv4'])
              l['active_ranges'].each do |lar|
                location.add_active_range Rack::AARM::DSL::ActiveRange.new(lar['from_date'], lar['to_date'])
              end
              vendor.add_location location
            end
            v['roles'].each do |r|
              role = Rack::AARM::DSL::Role.new(r['name'], r['password_plain'], r['password_md5'])
              r['active_ranges'].each do |ar|
                role.add_active_range Rack::AARM::DSL::ActiveRange.new(ar['from_date'], ar['to_date'])
              end
              r['rights'].each do |r|
                role.add_rights r['verbs'], r['on_resources']
              end
              vendor.roles << role
            end
          end
          vendors.add vendor
        end
        Rack::AARM::Configuration.vendors = vendors
        # Config resources
        resources = Rack::AARM::DSL::Resources.new
        config['resources'].each do |r|
          resource = Rack::AARM::DSL::Resource.new r['id'], r['name'], r['prefix']
          r['suffixes'].each do |s|
            suffix = Rack::AARM::DSL::Suffix.new Regexp.new(s['regex'].gsub(/^\(\?-mix:/,'').gsub(/\)$/,''))
            s['verbs'].each do |v|
              verb = Rack::AARM::DSL::Verb.new v['name']
              v['active_ranges'].each do |ar|
                verb.add_active_range Rack::AARM::DSL::ActiveRange.new(ar['from_date'], ar['to_date'])
              end
              suffix.verbs << verb
            end
            resource.suffixes << suffix
          end
          resources.add resource
        end
        Rack::AARM::Configuration.resources = resources
      rescue Exception => e
        @logger.error "Rack::AARM::Configuration: Unable to restore configuration from json [#{json}]\nException: #{e}\n#{e.backtrace.join('\n')}"
      end

      def self.restore_from_json_file(filename)
        json = ::IO.read(filename)
        restore_from_json json
      rescue Exception => e
        @logger.error "Rack::AARM::Configuration: Unable to restore configuration from file [#{filename}]\nException: #{e}\n#{e.backtrace.join('\n')}"
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