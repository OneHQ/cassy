# Cassy

This project is designed to be a Rails 3.0 engine that uses a large portion of the code from the [rubycas-server][https://github.com/gunark/rubycas-server] project. Certain portions of this code belong to the rubycas-server project owners.

## Installation

This engine currently only works with Rails 3.0. To have it work with the application you must do three things:

**Install as a gem**

Put this line in your project's `Gemfile`:

    gem 'cassy'

Create a new initializer (probably called `config/initializers/cassy.rb`) and point cassy at the correct configuration file of your application:

    Cassy::Engine.config.config_file = Rails.root + "config/cassy.yml"
    
Create this configuration file at `config/cassy.yml`. Fill it with these values:

    # Times are in seconds.
    maximum_unused_login_ticket_lifetime: 300
    maximum_unused_service_ticket_lifetime: 300

    authenticator:
      class: Cassy::Authenticators::Devise

The first two keys are the time-to-expiry for the login and service tickets respectively. The class for the authentication can be any constant which responds to a `validates` method. By default, only Devise authentication is supported at the moment.

Boom, done. Now this application will act as a CAS server.