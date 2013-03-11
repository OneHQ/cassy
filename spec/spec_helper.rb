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

VALID_USERNAME = 'spec_user'
VALID_PASSWORD = 'spec_password'

ATTACK_USERNAME = '%3E%22%27%3E%3Cscript%3Ealert%2826%29%3C%2Fscript%3E&password=%3E%22%27%3E%3Cscript%3Ealert%2826%29%3C%2Fscript%3E&lt=%3E%22%27%3E%3Cscript%3Ealert%2826%29%3C%2Fscript%3E&service=%3E%22%27%3E%3Cscript%3Ealert%2826%29%3C%2Fscript%3E'
INVALID_PASSWORD = 'invalid_password'
