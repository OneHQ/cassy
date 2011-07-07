module Cassy
  extend ActiveSupport::Autoload
  
  autoload :CAS
  autoload :Utils
  autoload :Engine

  def self.draw_routes
    Rails.application.routes.draw do
      scope(:path => "cas") do
        get 'login', :to => "cassy/sessions#new"
        post 'login', :to => "cassy/sessions#create"
        
        get 'logout', :to => "cassy/sessions#destroy"
        
        get 'serviceValidate', :to => "cassy/sessions#service_validate"
        get 'proxyValidate',   :to => "cassy/sessions#proxy_validate"
      end
    end
  end
  
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