module Cassy
  module Authenticators
    class Devise < Base
      def self.validate(credentials)
        # Find the user with the given email
        user = User.find_by_email(credentials[:username])
        # Did we find a user, and is their password valid?
        user && user.valid_password?(credentials[:password])
      end
    end
  end
end