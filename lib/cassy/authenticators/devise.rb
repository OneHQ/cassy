module Cassy
  module Authenticators
    class Devise < Base
      def self.validate(credentials)
        p credentials
      end
    end
  end
end