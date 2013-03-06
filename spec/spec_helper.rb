require 'webmock/rspec'
# Configure Rails Environment
ENV["RAILS_ENV"] = "test"
ENV["RUBYCAS_CONFIG_FILE"] = File.expand_path("default_config.yml", File.dirname(__FILE__))

require File.expand_path("../dummy/config/environment.rb",  __FILE__)

Rails.backtrace_cleaner.remove_silencers!

# Load support files
require 'rspec/core'
require 'rspec/rails'
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }
