require 'cassy/routes'

module Cassy
  extend ActiveSupport::Autoload
  
  autoload :CAS
  autoload :Utils
  autoload :Engine
  
  def self.root
    Pathname.new(File.dirname(__FILE__) + "../..")
  end
  
  # Just an easier way to get to the configuration for the engine
  def self.config
    Cassy::Engine.config.configuration
  end
  
  class AuthenticatorError < Exception
  end
end

require 'cassy/authenticators'
require 'cassy/engine'