require 'base64'

module Rack
  module AARM
    class APIKey

      attr_accessor :logger

      class << self

        def get_new_key_pair
          cipher = OpenSSL::Cipher::AES.new(128, :CBC)
          key = Base64.encode64(cipher.random_key).gsub(/\n/, '')
          cipher.encrypt
          cipher.key = key
          secret = Base64.encode64(cipher.random_iv).gsub(/\n/, '')
          return key, secret
        end

      end

      # Creates a new cipher class.
      # This uses a AES 128bit CBC cipher
      # The +api_key+ is in the clear
      # The +api_secret+ is never transmitted.
      #
      #   require 'rack/aarm/api_key'
      #   valid_api_key = 'HruYu1fWDENhOQyaIOPH4/P21Ik='
      #   valid_api_secret = 'NXiz6PpL0z5CuzCETekuTw=='
      #   params = {
      #       name: 'hello', field1: 'world'
      #   }
      #   cipher = Rack::AARM::APIKey.new(valid_api_key, valid_api_secret)
      #   cipher.logger.level = ::Logger::DEBUG
      #   encoded, iv = cipher.encrypt_this(params.to_json)
      #
      # A local logger is created to STDERR.
      #
      # <i>Generates:</i>
      #
      #    cipher instance
      def initialize(api_secret)
        @api_secret = api_secret
        begin
          @logger = Rack::AARM::Configuration.logger
        rescue
          @logger = ::Logger.new(STDERR)
        end
        @logger.info "Rack::AARM::APIKey: Generating AES 128bit CBC cipher"
        @cipher = OpenSSL::Cipher::AES.new(128, :CBC)
      end

      # Allows setting of the logger externally
      # Usage:
      #   cipher = Rack::AARM::APIKey.new(valid_api_key, valid_api_secret)
      #   cipher.logger.level = ::Logger::DEBUG
      def logger=(logger)
        @logger = logger
      end

      # Encrypts a string +json_string+
      # The string doesn't have to be json, but standard usage is as follows:
      #
      #   params = {
      #       name: 'hello', field1: 'world'
      #   }
      #   encoded, iv = cipher.encrypt_this(params.to_json)
      #
      # <i>Generates</i>
      #
      #   Base64 encoded strings (with potential embedded linefeeds)
      #   An IV64 cipher filler for use in decryption
      #
      # <i>Exceptions</i>
      #   If any failure occurs an error message is sent to the logger
      #   and nil, nil is returned
      def encrypt_this(json_string)
        begin
          @cipher.encrypt
          @cipher.key = @api_secret
          iv = Base64.encode64(@cipher.random_iv).gsub(/\n/, '')
          encrypted = @cipher.update(json_string) + @cipher.final
          encoded = Base64.encode64(encrypted).gsub(/\n/, '')
          @logger.debug "Rack::AARM::APIKey: Encode: [#{json_string}] Encoded64: [#{encoded}] iv64: [#{iv}]"
          return encoded, iv
        rescue Exception => e
          @logger.error "Rack::AARM::APIKey: Unable to encrypt [#{json_string}]\nException: #{e}\n#{e.backtrace.join("\n")}"
          return nil, nil
        end
      end

      # Decrypts a +base64_string+ and the associated filler returned from encrypt_this().
      # Usage:
      #   require 'rack/aarm/api_key'
      #   valid_api_key = 'HruYu1fWDENhOQyaIOPH4/P21Ik='
      #   valid_api_secret = 'NXiz6PpL0z5CuzCETekuTw=='
      #   params = {
      #       name: 'hello', field1: 'world'
      #   }
      #   cipher = Rack::AARM::APIKey.new(valid_api_key, valid_api_secret)
      #   cipher.logger.level = ::Logger::DEBUG
      #   encoded, iv = cipher.encrypt_this(params.to_json)
      #
      # <i>Generates</i>
      #
      #   Decoded plain string
      #
      # <i>Exceptions</i>
      #   If any failure occurs an error message is sent to the logger
      #   and nil is returned
      def decrypt_this(base64_string, iv64)
        begin
          @logger.debug "Rack::AARM::APIKey: Decode: [#{base64_string}] iv64: [#{iv64.gsub(/\n/, '')}]"
          @cipher.decrypt
          @cipher.key = @api_secret
          @cipher.iv = Base64.decode64(iv64)
          encrypted = Base64.decode64(base64_string)
          plain = @cipher.update(encrypted) + @cipher.final
          @logger.debug "Rack::AARM::APIKey: Decoded: [#{plain}]"
          plain
        rescue Exception => e
          @logger.error "Rack::AARM::APIKey: Unable to decrypt [#{base64_string}]\nException: #{e}\n#{e.backtrace.join("\n")}"
          return nil
        end
      end

    end
  end
end