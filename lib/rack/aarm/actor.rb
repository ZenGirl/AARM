module Rack
  module AARM

    class Actor

      def initialize(app)
        @app = app
        @logger = Rack::AARM::Configuration.logger
        @env = {}
      end

      def call(env)
        @logger.warn "Rack::AARM::Actor: Actor.call Received #{build_call_signature(env)}"
        @env = env
        @request = Rack::AARM::Request.new(env)
        http_code, verified, code, messages = verify
        if verified
          @app.call(env)
        else
          @logger.warn "Rack::AARM::Actor: Unverified call made: #{build_call_signature(env)}"
          [http_code, {}, [{code: code, messages: messages}.to_json]]
        end
      end

      private

      def build_call_signature(env)
        "#{env['rack.url_scheme']}://#{env['SERVER_NAME']}:#{env['SERVER_PORT']}#{env['PATH_INFO']}#{env['QUERY_STRING']}"
      end

      MESSAGE2_INVALID_HEADER = 'API calls must have an Authorisation header'
      MESSAGE2_BAD_VENDOR = 'API calls require an active vendor key'
      MESSAGE2_BAD_LOCATION = 'API calls require an active location header such as X-Real-IP, HTP_X_Real_IP or REMOTE_ADDR'
      MESSAGES = {
          '001' => "Missing Authorisation header",
          '002' => "Authorisation header is not a String",
          '003' => "Authorisation header is empty",
          '004' => "Authorisation header missing API-KEY and signature",
          '005' => "Authorisation header missing API-KEY",
          '006' => "Authorisation header missing signature",
          '007' => "Authorisation header has an unknown API-KEY",
          '008' => "That vendor is not active",
          '009' => "Your location is denied access",
          '010' => "No location header found. Expecting X-Real-IP, HTTP_X_Real_IP or REMOTE_ADDR",
          '011' => "Location provided but not active",
          '012' => "Signature formatted incorrectly. Read the docs.",
          '013' => "Only GET, POST, PUT, DELETE and HEAD allowed",
          '014' => "GET with a body? CONTENT_LENGTH != 0",
          '015' => "POST or PUT without multipart/form_data",
          '016' => "Parameters did not decrypt correctly"
      }

      def error_invalid(code)
        @logger.warn "Rack::AARM::Actor: Request denied due to [#{MESSAGES[code]}][#{MESSAGE2_INVALID_HEADER}]"
        return 401, false, code, [MESSAGES[code], MESSAGE2_INVALID_HEADER]
      end

      def error_bad_vendor(code)
        @logger.warn "Rack::AARM::Actor: Request denied due to [#{MESSAGES[code]}][#{MESSAGE2_BAD_VENDOR}]"
        return 401, false, code, [MESSAGES[code], MESSAGE2_BAD_VENDOR]
      end

      def error_bad_location(code)
        @logger.warn "Rack::AARM::Actor: Request denied due to [#{MESSAGES[code]}][#{MESSAGE2_BAD_LOCATION}]"
        return 401, false, code, [MESSAGES[code], MESSAGE2_BAD_LOCATION]
      end

      def check_authorisation_header(authorisation_header)
        return '001' if authorisation_header.nil?
        return '002' unless authorisation_header.is_a? String
        return '003' if authorisation_header.strip.empty?
        false
      end

      def verify
        # -----------------------------------------------------------------
        # Get the header
        # -----------------------------------------------------------------
        authorisation_header = @env['Authorisation']
        # -----------------------------------------------------------------
        # Barf if no header provided
        # -----------------------------------------------------------------
        #(error_code = check_authorisation_header(authorisation_header)) and return error_invalid(error_code) if error_code
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
        encrypted64, iv64 = signature.split('_')
        return error_invalid('012') if encrypted64.nil? or encrypted64.strip.empty?
        return error_invalid('012') if iv64.nil? or iv64.strip.empty?
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
          #TODO Search database
        end
        return error_bad_vendor('007') if vendor.nil?
        return error_bad_vendor('008') unless vendor[:active]
        if vendor[:use_locations]
          # ---------------------------------------------------------------
          # NGinx uses X-Real-IP
          # Apache uses HTTP_X_Real_IP and/or REMOTE_ADDR
          # ---------------------------------------------------------------
          ipv4 = @env['X-Real-IP'] || @env['HTTP_X_Real_IP'] || @env['REMOTE_ADDR']
          return error_invalid('010') unless ipv4
          # ---------------------------------------------------------------
          # It has an ipv4 address. Find it
          # ---------------------------------------------------------------
          if Rack::AARM::Configuration.environment == :test
            location = nil
            Rack::AARM::Configuration.locations.each do |loc|
              if loc[:vendor_id] == vendor[:name] and loc[:ipv4] == ipv4
                location = loc
                break
              end
            end
            return error_bad_location('009') unless location
            return error_bad_location('011') unless location[:active]
          else
            #TODO Search database
          end
        end
        # -------------------------------------------------------------------
        # Create a sorted params hash from the QueryString and body content
        # -------------------------------------------------------------------
        query_string = @env['QUERY_STRING']
        body = @env["rack.input"].read
        @logger.debug "Rack::AARM::ApiKey: [#{@env['REQUEST_METHOD']}] query_string[#{query_string}] body[#{body}]"
        case @env['REQUEST_METHOD']
          when 'GET' # No body allowed
            error_invalid('014') if @env['CONTENT_LENGTH'] != "0"
          when 'POST' # Must be multipart/form-data and CONTENT_LENGTH must match body length
            error_invalid('015') unless @env['CONTENT_TYPE'] =~ /^multipart\/form-data/
            error_invalid('014') if @env['CONTENT_LENGTH'] != body.size
          when 'PUT' # Must be multipart/form-data and CONTENT_LENGTH must match body length
            error_invalid('015') unless @env['CONTENT_TYPE'] =~ /^multipart\/form-data/
            error_invalid('014') if @env['CONTENT_LENGTH'] != body.size
          when 'DELETE' # No body allowed
            error_invalid('014') if @env['CONTENT_LENGTH'] != "0"
          when 'HEAD' # Dang it.
            error_invalid('014') if @env['CONTENT_LENGTH'] != "0"
          else # Barf
            return error_invalid('013')
        end

        #ap Rack::Utils.parse_nested_query(query_string)#.deep_symbolize_keys

        all_params = {}.merge(JSON.parse(body)).merge(Rack::Utils.parse_nested_query(query_string))
        @logger.debug "Rack::AARM::Actor: all_params[#{all_params}]"
        @logger.debug "Rack::AARM::Actor: all_params[#{all_params.sort}]"
        json_string = Hash[all_params.sort].to_json
        @logger.debug "Rack::AARM::Actor: json_string[#{json_string}]"
        # -------------------------------------------------------------------
        # Decrypt the signature and ensure it matches
        # -------------------------------------------------------------------
        cipher = Rack::AARM::APIKey.new(vendor[:api_secret])
        plain_result = cipher.decrypt_this(encrypted64, iv64)
        @logger.debug "Rack::AARM::Actor: plain_result[#{plain_result}] json_string[#{json_string}]"
        return error_invalid('016') if json_string != plain_result
        @logger.debug "Rack::AARM::Actor: Decrypted signature matches parameters"
        # -------------------------------------------------------------------
        # Find the resource
        # -------------------------------------------------------------------
        #TODO Check the resource
        # -------------------------------------------------------------------
        # All done and passed!
        # -------------------------------------------------------------------
        @logger.debug "Rack::AARM::ApiKey: Passing request on to application #{@env['PATH_INFO']}"
        return 200, true, '000', %w(Failed Failed)
      end

      def logger=(logger)
        @logger = logger
      end

      def self.messages
        MESSAGES
      end

    end

  end
end
