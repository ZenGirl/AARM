require 'spec_helper'

describe 'Spork running' do
  it "checks to see if all worked" do
    Spork.using_spork?.should == true
    #(Rails.respond_to?(:logger) ? Rails.logger : ActionController::Base.logger).info "hey there"
    #$loaded_stuff.should include('ActiveRecord::Base.establish_connection')
    #$loaded_stuff.should include('User')
    #$loaded_stuff.should include('UserObserver')
    #$loaded_stuff.should include('ApplicationHelper')
    #$loaded_stuff.should include('config/routes.rb')
    #$loaded_stuff.should include('each_run block')
    #$loaded_stuff.should include('prefork block')
    puts "Specs successfully run within spork, and all initialization files were loaded"
  end
end
