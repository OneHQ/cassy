module Cassy
  module Authenticators
    extend ActiveSupport::Autoload
    
    autoload :Base
    autoload :Devise
    autoload :Test
  end
end