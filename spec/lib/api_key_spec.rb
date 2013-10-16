require 'spec_helper'
require 'rspec'
require 'rack'
require 'rack/test'
require 'json'

require 'aarm'
require 'rack/aarm/api_key'

describe Rack::AARM do

  describe Rack::AARM::APIKey do

    before do
      @params = {
          name: 'hello', field1: 'world'
      }
      @valid_api_secret = 'NXiz6PpL0z5CuzCETekuTw=='
      @cipher = Rack::AARM::APIKey.new(@valid_api_secret)
      @cipher.logger.level = ::Logger::DEBUG

    end

    # -----------------------------------------------------------------------
    # Encryption and Decryption
    # -----------------------------------------------------------------------
    it "Encrypts and Decrypts the signature with valid secret" do
      encoded, iv = @cipher.encrypt_this(@params.to_json)
      plain_json = @cipher.decrypt_this(encoded, iv)
      expect(plain_json).to eql(@params.to_json)
    end

    it "Decryption fails if the filler is invalid" do
      encoded, _ = @cipher.encrypt_this(@params.to_json)
      plain_json = @cipher.decrypt_this(encoded, 'rubbish')
      expect(plain_json).to be_nil
    end

    it "Decryption fails if the secret is invalid" do
      encoded, iv = @cipher.encrypt_this(@params.to_json)
      cipher = Rack::AARM::APIKey.new('junk')
      plain_json = cipher.decrypt_this(encoded, iv)
      expect(plain_json).to be_nil
    end

  end
end
