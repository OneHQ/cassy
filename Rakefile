#!/usr/bin/env rake
begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

# load rspec so we can set up the environment correctly using spec_helper
require 'rspec/core/rake_task'
require_relative './spec/spec_helper.rb'
RSpec::Core::RakeTask.new(:spec)

Bundler::GemHelper.install_tasks

# load our dummy app so we have access to rails rake tasks such as db:create and db:migrate
APP_RAKEFILE = File.expand_path("../spec/dummy/Rakefile", __FILE__)
begin
  load 'rails/tasks/engine.rake'
rescue LoadError
  # for Rails 3.0.x we need to load the Rakefile directly, as the engine rake task doesn't exist
  load APP_RAKEFILE
end

task(:default).clear
task :default => [
  'db:create',
  'db:migrate',
  'spec'
]
