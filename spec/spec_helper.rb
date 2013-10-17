require 'rubygems'
require 'spork'

ENV['RACK_ENV'] = 'test'

Spork.prefork do

  require 'bundler/setup'
  require 'active_record'
  require 'rspec'
  require 'factory_girl'
  require 'rack/test'

  # -------------------------------------------------------------------------
  # Configure database and connection
  # -------------------------------------------------------------------------
  #database_yml = File.join(__dir__, '..', 'config', 'database.yml')
  #default_conf = YAML::load_file(database_yml)
  #ActiveRecord::Base.establish_connection(default_conf['test'])

  # -------------------------------------------------------------------------
  # Configure rspec
  # -------------------------------------------------------------------------
  RSpec.configure do |config|
    # -----------------------------------------------------------------------
    # Run specs in random order to surface order dependencies. If you find an
    # order dependency and want to debug it, you can fix the order by providing
    # the seed, which is printed after each run.
    #     --seed 1234
    # -----------------------------------------------------------------------
    #config.order = "random"

    # -----------------------------------------------------------------------
    # Include FactoryGirl syntax methods
    # -----------------------------------------------------------------------
    config.include FactoryGirl::Syntax::Methods

    # -----------------------------------------------------------------------
    # Rack test
    # -----------------------------------------------------------------------
    config.include Rack::Test::Methods

    require_relative 'lib/helpers'
    config.include Helpers

  end

end

Spork.each_run do
  # -------------------------------------------------------------------------
  # Checks for pending migrations before tests are run.
  # If you are not using ActiveRecord, you can remove this line.
  # -------------------------------------------------------------------------
  #ActiveRecord::Migration.check_pending! if defined?(ActiveRecord::Migration)

  # -------------------------------------------------------------------------
  # Require files
  # -------------------------------------------------------------------------
  require_relative '../lib/aarm'

end

# --- Instructions ---
# Sort the contents of this file into a Spork.prefork and a Spork.each_run
# block.
#
# The Spork.prefork block is run only once when the spork server is started.
# You typically want to place most of your (slow) initializer code in here, in
# particular, require'ing any 3rd-party gems that you don't normally modify
# during development.
#
# The Spork.each_run block is run each time you run your specs.  In case you
# need to load files that tend to change during development, require them here.
# With Rails, your application modules are loaded automatically, so sometimes
# this block can remain empty.
#
# Note: You can modify files loaded *from* the Spork.each_run block without
# restarting the spork server.  However, this file itself will not be reloaded,
# so if you change any of the code inside the each_run block, you still need to
# restart the server.  In general, if you have non-trivial code in this file,
# it's advisable to move it into a separate file so you can easily edit it
# without restarting spork.  (For example, with RSpec, you could move
# non-trivial code into a file spec/support/my_helper.rb, making sure that the
# spec/support/* files are require'd from inside the each_run block.)
#
# Any code that is left outside the two blocks will be run during preforking
# *and* during each_run -- that's probably not what you want.
#
# These instructions should self-destruct in 10 seconds.  If they don't, feel
# free to delete them.



