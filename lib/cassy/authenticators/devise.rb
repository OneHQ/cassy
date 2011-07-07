module Cassy
  module Authenticators
    class Devise < Base
      
      def self.find_user(credentials)
        # Find the user with the given email
        method = "find_by_#{Cassy.config[:username_field] || 'email'}"
        User.send(method, credentials[:username])
      end
      
      def self.validate(credentials)
        user = find_user(credentials)
        # Did we find a user, and is their password valid?
        user && user.valid_password?(credentials[:password])
      end
    end
  end
end