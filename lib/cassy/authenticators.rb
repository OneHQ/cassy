module Cassy
  module Authenticators
    extend ActiveSupport::Autoload
    
    autoload :Base
    autoload :SQL
    autoload :SQLAuthlogic
    autoload :Test
  end
end