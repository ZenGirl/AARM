module Rack
  module AARM

    class Actor

      def initialize(app)
        @app = app
        @logger = Rack::AARM::Configuration.logger
        @env = {}
      end

      def call(env)
        @logger.warn "AARM: Actor.call Received #{env['REQUEST_METHOD']}:#{env['SERVER_NAME']}:#{env['SERVER_PORT']}:#{env['PATH_INFO']} #{env['QUERY_STRING']}"
        @env = env
        @request = Rack::AARM::Request.new(env)
        verified, code, messages = verify
        if verified
          @app.call(env)
        else
          @logger.warn "AARM: Unverified call made: #{build_call_signature(env)}"
          [401, {}, [{code: code, messages: messages}.to_json]]
        end
      end

      private

      def build_call_signature(env)
        "#{env['rack.url_scheme']}://#{env['SERVER_NAME']}:#{env['SERVER_PORT']}#{env['PATH_INFO']}#{env['QUERY_STRING']}"
      end

      MESSAGE2_INVALID_HEADER = 'API calls must have an Authorisation header'
      MESSAGE2_BAD_VENDOR = 'API calls require an active vendor key'
      MESSAGES = {
          '001' => "Missing Authorisation header",
          '002' => "Authorisation header is not a String",
          '003' => "Authorisation header is empty",
          '004' => "Authorisation header missing API-KEY and signature",
          '005' => "Authorisation header missing API-KEY",
          '006' => "Authorisation header missing signature",
          '007' => "Authorisation header has an unknown API-KEY",
          '008' => "That vendor is not active",
          '009' => "Your location is denied access"
      }

      def verify
        authorisation_header = @env['Authorisation']
        return error_invalid('001') if authorisation_header.nil?
        return error_invalid('002') if !authorisation_header.is_a? String
        return error_invalid('003') if authorisation_header.strip.empty?
        # -----------------------------------------------------------------
        # Split up the header and start work
        # -----------------------------------------------------------------
        api_key, signature = authorisation_header.split(/:/)
        return error_invalid('004') if (api_key.nil? or api_key.strip.empty?) and (signature.nil? or signature.strip.empty?)
        return error_invalid('005') if api_key.nil? or api_key.strip.empty?
        return error_invalid('006') if signature.nil? or signature.strip.empty?
        # ---------------------------------------------------------------
        # Ok. We got this far. Validate the API-KEY
        # ---------------------------------------------------------------
        vendor = nil
        if Rack::AARM::Configuration.environment == :test
          Rack::AARM::Configuration.vendors.each do |v|
            if v[:api_key] == api_key
              vendor = v
              break
            end
          end
        else
          # Search database
        end
        return error_bad_vendor('007') if vendor.nil?
        return error_bad_vendor('008') unless vendor[:active]
        if vendor[:use_locations]
          ap @env
          @logger.debug @env
        end
        # ---------------------------------------------------------------
        # Find the resource
        # ---------------------------------------------------------------
        @logger.debug "Searching for #{@env['PATH_INFO']}"
        return false, '000', %w(Failed Failed)
      end

      def logger=(logger)
        @logger = logger
      end

      def self.messages
        MESSAGES
      end

      def error_invalid(code)
        @logger.warn "AARM: Request denied due to #{MESSAGES[code]}"
        return false, code, [MESSAGES[code], MESSAGE2_INVALID_HEADER]
      end

      def error_bad_vendor(code)
        @logger.warn "AARM: Request denied due to #{MESSAGES[code]}"
        return false, code, [MESSAGES[code], MESSAGE2_BAD_VENDOR]
      end

    end

  end
end
