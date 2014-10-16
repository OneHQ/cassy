module Cassy
  module Authenticators
    class Devise < Base

      def self.find_user(credentials)
        # Find the user with the given email
        method = "find_by_#{Cassy.config[:username_field] || 'email'}"
        User.send(method, credentials[:username])
      end

      def self.find_user_from_ticket(ticket)
        return if ticket.nil?
        key  = Cassy.config[:client_app_user_field] || Cassy.config[:username_field] || "email"
        method = "find_by_#{key}"
        User.send(method, ticket.username)
      end

      def self.validate(credentials)
        user = find_user(credentials)
        # Did we find a user, are they active? and is their password valid?
        user && user.active_for_authentication? && user.valid_for_authentication? { user.valid_password?(credentials[:password]) }
      end
    end
  end
end
