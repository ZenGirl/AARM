module Helpers
  def with_call(req, path)
    request = Rack::MockRequest.new(Rack::AARM::Actor.new(req))
    response = request.get(path)
    yield(response) if block_given?
  end

  def validate_code_and_messages(res, code, message1, message2)
    parsed = JSON.parse(res.body)
    expect(parsed['code']).to eq(code)
    expect(parsed['messages'].size).to eq(2)
    expect(parsed['messages'][0]).to eq(message1)
    expect(parsed['messages'][1]).to eq(message2)
  end

  def all_crud_options
    %w(C___ CR__ CRU_ CRUD C_U_ C_UD C__D CR_D _R__ _RU_ _R_D _RUD __U_ __UD ___D)
  end

  def get_cipher_for(api_secret)
    cipher = Rack::AARM::APIKey.new(api_secret)
    cipher.logger.level = ::Logger::DEBUG
    cipher.logger.datetime_format = '%Y-%m-%d %H:%M:%S'
    cipher.logger.formatter = proc do |severity, datetime, progname, msg|
      "                #{datetime.utc}: [#{severity.ljust(8)}] #{msg}\n"
    end
    cipher
  end
end