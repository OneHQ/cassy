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

Next, you will need to tell Cassy to load its routes in your application which you can do by calling `cassy` in `config/routes.rb`:

    Rails.application.routes.draw do
      cassy
      
      # your routes go here
    end

Boom, done. Now this application will act as a CAS server.

For customization options please see the "Customization" section below.

## Configuration

The configuration options for this gem goes into a file called `config/cassy.yml` at the root of the project if you've set it up as advised, and this allows the engine to be configured.

These configuration options are detailed here for your convenience. For specific term definitions, please consult the CAS spec.

`authenticator`: Must specify at least one key, `class`, which is a string version of a constant that will be used for authentication in the system. This constant *must* respond to `validate`.
`maximum_unused_login_ticket_lifetime`: The time before a login ticket would expire.
`maximum_unused_service_ticket_lifetime`: The time before a service ticket would expire.
`username_field`: Defines the field on the users table which is used for the lookup for the username. Defaults to "username".
`username_label`: Allows for the "Username" label on the sign in page to be given a different value. Helpful if you want to call it "Email" or "User Name" instead.
'client_app_user_field'
'service_list'

Here is a sample cassy.yml file:

maximum_unused_login_ticket_lifetime: 7200
maximum_unused_service_ticket_lifetime: 7200
maximum_session_lifetime: 7200
  username_field: username
  client_app_user_field: id
service_list:
  # production
  - https://agencieshq.com/users/service
  - https://administratorshq.agencieshq.com/users/service
  # development
  - http://localhost:3000/users/service
  - http://localhost:3001/users/service
  - http://localhost:3002/users/service
authenticator:
  class: Cassy::Authenticators::Devise
extra_attributes:
  - user_id
  - user_username

## Customization

### Sessions Controller

In Cassy, it is possible to override the controller which is used for authentication. To do this, the controller can be configured in `config/routes.rb`:

    cassy :controllers => "sessions"

By doing this, it will point at the `SessionsController` rather than the default of `Cassy::SessionsController`. This controller then should inherit from `Cassy::SessionsController` to inherit the original behaviour and will need to point to the views of Cassy:

    class SessionsController < Cassy::SessionsController
      def new
        # custom behaviour goes here
        super
      end
        
 