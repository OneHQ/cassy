# encoding: UTF-8
require 'cassy/authenticators/base'

# Dummy authenticator used for testing.
# Accepts any username as valid as long as the password is "testpassword"; otherwise authentication fails.
# Raises an AuthenticationError when username is "do_error" (this is useful to test the Exception
# handling functionality).
class Cassy::Authenticators::Test < Cassy::Authenticators::Base
  def self.validate(credentials)
    read_standard_credentials(credentials)

    raise Cassy::AuthenticatorError, "Username is 'do_error'!" if @username == 'do_error'

    valid_password = options[:password] || "testpassword"

    return @password == valid_password
  end

  def self.find_user(*args)
    # To stop NotImplementedError raising
    @user = Object.new
    def @user.full_name
      "Example User"
    end
    def @user.username
      "Users Username"
    end
    @user
  end

  class << self
    alias_method :find_user_from_ticket, :find_user
  end
end
