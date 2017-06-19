# Cassy

This project is designed to be a Rails engine that uses a large portion of the code from the [rubycas-server][https://github.com/gunark/rubycas-server] project. Certain portions of this code belong to the rubycas-server project owners.

## Installation

This engine currently only works with Rails 3 and above. To have it work with the application you must do four things:

1. Put this line in your project's `Gemfile`:

```
gem 'cassy'
```

2. Create a configuration file at `config/cassy.yml` and fill it with these values:

```
# Times are in seconds.
maximum_unused_login_ticket_lifetime: 300
maximum_unused_service_ticket_lifetime: 300

authenticator:
  class: Cassy::Authenticators::Devise
```

The first two keys are the time-to-expiry for the login and service tickets respectively. The class for the authentication can be any constant which responds to a `validates` method. Only Devise authentication is supported at the moment.

3. Create a new initializer (probably called `config/initializers/cassy.rb`) and point cassy at the configuration file for your application:

```
Cassy::Engine.config.config_file = Rails.root + "config/cassy.yml"
```

4. Tell Cassy to load its routes in your application by calling `cassy` in `config/routes.rb`:

```
Rails.application.routes.draw do
  cassy

  # your routes go here
end
```

Boom, done. Now this application will act as a CAS server.

For customization options please see the "Customization" section below.

## Configuration

The configuration options for this gem goes into a file called `config/cassy.yml` at the root of the project if you've set it up as advised, and this allows the engine to be configured.

These configuration options are detailed here for your convenience. For specific term definitions, please consult the CAS spec.

* `authenticator`: Must specify at least one key, `class`, which is a string version of a constant that will be used for authentication in the system. This constant *must* respond to `validate`.
* `maximum_unused_login_ticket_lifetime`: The time before a login ticket would expire.
* `maximum_unused_service_ticket_lifetime`: The time before a service ticket would expire.
* `username_field`: Defines the field on the users table which is used for the lookup for the username. Defaults to " username".
* `username_label`: Allows for the "Username" label on the sign in page to be given a different value. Helpful if you want to call it "Email" or "User Name" instead.
* `client_app_user_field`: Defines the field name for the username on the *client* application side.
* `service_list`: List of services that use this server to authenticate, separated by environment.
* `default_redirect_url`: If the requested service isn't in the service_list (or is blank) then tickets will be generated for the valid services then the user will be redirected to here. Needs to be specified per environment as per the sample below. The default_redirect_url needs to be on the same domain as (at least) one of the urls on the service_list.
* `loosely_match_services`: If this is set to true, a request for the service http://www.something.com/something_else can be matched to the ticket for http://www.something.com.
* `enable_single_sign_out`: If this is set to true, calling send_logout_notification on a service ticket will send a request to the service telling it to clear the associated users session. Calling destroy_and_logout_all_service_tickets on a ticket granting ticket will send a session-terminating request to each service before destroying itself.
* `no_concurrent_sessions`: (requires enable_single_sign_out to be true) If this is true, when someone logs in, a session-terminating request is sent to each service for any old service tickets related to the current user.
* `concurrent_session_types`:  If no_concurrent_sessions is true, concurrent_session_types can be specified so that a user can have concurrent sessions on different device types.  If enabled, override `session_type` in `SessionsController` to return the session_type (any string).

A sample `cassy.yml` file:

```
maximum_unused_login_ticket_lifetime: 7200
maximum_unused_service_ticket_lifetime: 7200
maximum_session_lifetime: 7200
  username_field: username
  client_app_user_field: id
service_list:
  production:
  - https://agencieshq.com/users/service
  - https://administratorshq.agencieshq.com/users/service
  development:
  - http://localhost:3000/users/service
  - http://localhost:3001/users/service
  - http://localhost:3002/users/service
default_redirect_url:
  development: http://localhost:3000
  production: http://www.something.com
loosely_match_services: true
authenticator:
  class: Cassy::Authenticators::Devise
no_concurrent_sessions: true
concurrent_session_types: [:mobile, :desktop]
extra_attributes:
  - user_id
  - user_username
```

## Customization

### Sessions Controller

In Cassy, it is possible to override the controller which is used for authentication. To do this, the controller can be configured in `config/routes.rb`:

```
cassy :controllers => "sessions"
```

By doing this, it will point at the `SessionsController` rather than the default of `Cassy::SessionsController`. This controller then should inherit from `Cassy::SessionsController` to inherit the original behaviour and will need to point to the views of Cassy:

```
class SessionsController < Cassy::SessionsController
  def new
    # custom behaviour goes here
    super
  end
end
```

## Contributing

### Versioning

We use [Semantic Versioning](http://semver.org/) for our open source dependencies, and a modified version of Semantic Versioning in our internal dependencies.

#### Open Source

`MAJOR.MINOR.PATCH`

**1** MAJOR version when you make incompatible API changes

**2** MINOR version when you add functionality in a backwards-compatible manner, and

**3** PATCH version when you make backwards-compatible bug fixes.

#### Internal

**1** MAJOR version when major changes are made.

**2** MINOR version when you make incompatible API changes

**3** PATCH version when you make any backwards-compatible change.

### Releasing

#### Prerequisites

- Gemfury CLI installed
- Gemfury Credentials from 1Password

#### Instructions

**1.** Update `lib/{gem_name}/version.rb` according to the versioning rules above.

**2.** Create a Pull Request with the version change to the repository.

**3.** Once the pull request is merged, run `gem build .{gem_name}.gemspec`

**4.** Run `fury push {gem_name}_{version}.gem`.
