guard 'spork', :rspec => true, :cucumber => false, :test_unit => false, :bundler => false do
  watch('config/database.yml')
  watch('Gemfile.lock')
  watch('spec/spec_helper.rb') { :rspec }
  watch(%r{features/support/}) { :cucumber }
end

guard :rspec, :wait => 20, :all_after_pass => false, cli: '--color --format nested --fail-fast --drb' do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^spec/lib/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})             { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch(%r{^lib/rack/(.+)\.rb$})        { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch(%r{^lib/rack/aarm/(.+)\.rb$})   { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec" }
end

