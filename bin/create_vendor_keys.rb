require 'base64'
require 'openssl'
require 'logger'

class Colors
  COLOR1 = "\e[1;36;40m"
  COLOR2 = "\e[1;35;40m"
  NOCOLOR = "\e[0m"
  RED = "\e[1;31;40m"
  GREEN = "\e[1;32;40m"
  DARKGREEN = "\e[0;32;40m"
  YELLOW = "\e[1;33;40m"
  DARKCYAN = "\e[0;36;40m"
end

class String
  def color(color)
    color + self + Colors::NOCOLOR
  end
end

puts "****************************************".color(Colors::YELLOW)
puts "* Generating new vendor key and secret *".color(Colors::YELLOW)
puts "*                                      *".color(Colors::YELLOW)
puts "* Creating new AES 128bit CBC cipher   *".color(Colors::YELLOW)
cipher = OpenSSL::Cipher::AES.new(128, :CBC)
puts "*                                      *".color(Colors::YELLOW)
puts "* Generating random key:               *".color(Colors::YELLOW)
key = cipher.random_key
vendor_key = Base64.encode64(key).gsub(/\n/,'')
puts "*                                      *".color(Colors::YELLOW)
puts "*    #{vendor_key.color(Colors::RED)}          *".color(Colors::YELLOW)
puts "*                                      *".color(Colors::YELLOW)
puts "* Generating secret:                   *".color(Colors::YELLOW)
puts "*                                      *".color(Colors::YELLOW)
cipher.encrypt
cipher.key = key
secret = Base64.encode64(cipher.random_iv).gsub(/\n/,'')
puts "*    #{secret.color(Colors::RED)}          *".color(Colors::YELLOW)
puts "*                                      *".color(Colors::YELLOW)
puts "* Testing:                             *".color(Colors::YELLOW)
puts "*                                      *".color(Colors::YELLOW)
puts "* Loading AARM APIKey:                 *".color(Colors::YELLOW)
require_relative '../lib/rack/aarm/api_key'
api = Rack::AARM::APIKey.new(secret)
api.logger = ::Logger.new(STDERR)
api.logger.level = ::Logger::DEBUG
puts "*                                      *".color(Colors::YELLOW)
puts "* Encrypting 'Dummy Message':          *".color(Colors::YELLOW)
message = "Dummy Message"
encoded, iv = api.encrypt_this message
puts "*                                      *".color(Colors::YELLOW)
puts "* Decrypting:                          *".color(Colors::YELLOW)
str = api.decrypt_this encoded, iv
puts "* Result:                              *".color(Colors::YELLOW)
puts "*   message: [#{message}]           *".color(Colors::YELLOW)
puts "*   decoded: [#{str}]           *".color(Colors::YELLOW)
puts "****************************************".color(Colors::YELLOW)
