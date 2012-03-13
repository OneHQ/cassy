require 'uri'
require 'net/https'

require 'cassy/models'
require 'cassy/utils'

# Encapsulates CAS functionality. This module is meant to be included in
# the Cassy::Controllers module.
module Cassy
  module CAS

    class Error
      attr_reader :code, :message

      def initialize(code, message)
        @code = code
        @message = message
      end

      def to_s
        message
      end
    end
    
    def settings
      Cassy.config
    end

    def generate_login_ticket
      # 3.5 (login ticket)
      lt = Cassy::LoginTicket.new
      lt.ticket = "LT-" + Cassy::Utils.random_string

      lt.client_hostname = env['HTTP_X_FORWARDED_FOR'] || env['REMOTE_HOST'] || env['REMOTE_ADDR']
      lt.save!
      logger.debug("Generated login ticket '#{lt.ticket}' for client at '#{lt.client_hostname}'")
      lt
    end

    # Creates a TicketGrantingTicket for the given username. This is done when the user logs in
    # for the first time to establish their SSO session (after their credentials have been validated).
    #
    # The optional 'extra_attributes' parameter takes a hash of additional attributes
    # that will be sent along with the username in the CAS response to subsequent
    # validation requests from clients.
    def generate_ticket_granting_ticket(username, extra_attributes={})
      # 3.6 (ticket granting cookie/ticket)
      tgt = Cassy::TicketGrantingTicket.new
      tgt.ticket = "TGC-" + Cassy::Utils.random_string
      tgt.username = username
      tgt.extra_attributes = extra_attributes
      tgt.client_hostname = env['HTTP_X_FORWARDED_FOR'] || env['REMOTE_HOST'] || env['REMOTE_ADDR']
      tgt.save!
      tgt
    end

    def generate_service_ticket(service, username, tgt)
      # 3.1 (service ticket)
      st = ServiceTicket.new
      st.ticket = "ST-" + Cassy::Utils.random_string
      st.service = service
      st.username = username
      st.granted_by_tgt_id = tgt.id
      st.client_hostname = env['HTTP_X_FORWARDED_FOR'] || env['REMOTE_HOST'] || env['REMOTE_ADDR']
      st.save!
      logger.debug("Generated service ticket '#{st.ticket}' for service '#{st.service}'" +
        " for user '#{st.username}' at '#{st.client_hostname}'")
      st
    end

    def find_or_generate_service_tickets(username, tgt)
      @service_tickets={}
      valid_services.each do |service|
        @service_tickets[service] = generate_service_ticket(service, username, tgt)
      end
    end

    def valid_services
      @valid_services || settings[:service_list]
    end

    def generate_proxy_ticket(target_service, pgt)
      # 3.2 (proxy ticket)
      pt = ProxyTicket.new
      pt.ticket = "PT-" + Cassy::Utils.random_string
      pt.service = target_service
      pt.username = pgt.service_ticket.username
      pt.granted_by_pgt_id = pgt.id
      pt.granted_by_tgt_id = pgt.service_ticket.granted_by_tgt.id
      pt.client_hostname = @env['HTTP_X_FORWARDED_FOR'] || @env['REMOTE_HOST'] || @env['REMOTE_ADDR']
      pt.save!
      logger.debug("Generated proxy ticket '#{pt.ticket}' for target service '#{pt.service}'" +
        " for user '#{pt.username}' at '#{pt.client_hostname}' using proxy-granting" +
        " ticket '#{pgt.ticket}'")
      pt
    end

    def generate_proxy_granting_ticket(pgt_url, st)
      uri = URI.parse(pgt_url)
      https = Net::HTTP.new(uri.host,uri.port)
      https.use_ssl = true

      # Here's what's going on here:
      #
      #   1. We generate a ProxyGrantingTicket (but don't store it in the database just yet)
      #   2. Deposit the PGT and it's associated IOU at the proxy callback URL.
      #   3. If the proxy callback URL responds with HTTP code 200, store the PGT and return it;
      #      otherwise don't save it and return nothing.
      #
      https.start do |conn|
        path = uri.path.empty? ? '/' : uri.path
        path += '?' + uri.query unless (uri.query.nil? || uri.query.empty?)
      
        pgt = ProxyGrantingTicket.new
        pgt.ticket = "PGT-" + Cassy::Utils.random_string(60)
        pgt.iou = "PGTIOU-" + Cassy::Utils.random_string(57)
        pgt.service_ticket_id = st.id
        pgt.client_hostname = @env['HTTP_X_FORWARDED_FOR'] || @env['REMOTE_HOST'] || @env['REMOTE_ADDR']

        # FIXME: The CAS protocol spec says to use 'pgt' as the parameter, but in practice
        #         the JA-SIG and Yale server implementations use pgtId. We'll go with the
        #         in-practice standard.
        path += (uri.query.nil? || uri.query.empty? ? '?' : '&') + "pgtId=#{pgt.ticket}&pgtIou=#{pgt.iou}"

        response = conn.request_get(path)
        # TODO: follow redirects... 2.5.4 says that redirects MAY be followed
        # NOTE: The following response codes are valid according to the JA-SIG implementation even without following redirects
      
        if %w(200 202 301 302 304).include?(response.code)
          # 3.4 (proxy-granting ticket IOU)
          pgt.save!
          logger.debug "PGT generated for pgt_url '#{pgt_url}': #{pgt.inspect}"
          pgt
        else
          logger.warn "PGT callback server responded with a bad result code '#{response.code}'. PGT will not be stored."
          nil
        end
      end
    end

    def validate_ticket_granting_ticket(ticket)
      logger.debug("Validating ticket granting ticket '#{ticket}'")

      if ticket.nil?
        error = "No ticket granting ticket given."
        logger.debug error
      elsif tgt = TicketGrantingTicket.find_by_ticket(ticket)
        if settings[:maximum_session_lifetime] && Time.now - tgt.created_on > settings[:maximum_session_lifetime]
  	tgt.destroy
          error = "Your session has expired. Please log in again."
          logger.info "Ticket granting ticket '#{ticket}' for user '#{tgt.username}' expired."
        else
          logger.info "Ticket granting ticket '#{ticket}' for user '#{tgt.username}' successfully validated."
        end
      else
        error = "Invalid ticket granting ticket '#{ticket}' (no matching ticket found in the database)."
        logger.warn(error)
      end

      [tgt, error]
    end

    def service_uri_with_ticket(service, st)
      raise ArgumentError, "Second argument must be a ServiceTicket!" unless st.kind_of? Cassy::ServiceTicket

      # This will choke with a URI::InvalidURIError if service URI is not properly URI-escaped...
      # This exception is handled further upstream (i.e. in the controller).
      service_uri = URI.parse(service)
      if service.include? "?"
        if service_uri.query.empty?
          query_separator = ""
        else
          query_separator = "&"
        end
      else
        query_separator = "?"
      end

      service_with_ticket = service + query_separator + "ticket=" + st.ticket
      service_with_ticket
    end

    # Strips CAS-related parameters from a service URL and normalizes it,
    # removing trailing / and ?. Also converts any spaces to +.
    #
    # For example, "http://google.com?ticket=12345" will be returned as
    # "http://google.com". Also, "http://google.com/" would be returned as
    # "http://google.com".
    #
    # Note that only the first occurance of each CAS-related parameter is
    # removed, so that "http://google.com?ticket=12345&ticket=abcd" would be
    # returned as "http://google.com?ticket=abcd".
    def clean_service_url(dirty_service)
      return dirty_service if dirty_service.blank?
      clean_service = dirty_service.dup
      ['service', 'ticket', 'gateway', 'renew'].each do |p|
        clean_service.sub!(Regexp.new("&?#{p}=[^&]*"), '')
      end

      clean_service.gsub!(/[\/\?&]$/, '') # remove trailing ?, /, or &
      clean_service.gsub!('?&', '?')
      clean_service.gsub!(' ', '+')

      logger.debug("Cleaned dirty service URL #{dirty_service.inspect} to #{clean_service.inspect}") if
        dirty_service != clean_service

      return clean_service
    end
    module_function :clean_service_url

    def base_service_url(full_service_url)
      # strips a url back to the domain part only 
      # so that a service ticket can work for all urls on a given domain
      # eg http://www.something.com/something_else
      # is stripped back to
      # http://www.something.com
      # expects it to be in 'http://x' form
      return unless full_service_url
      match = full_service_url.match(/(http(s?):\/\/[a-z0-9\.:]*)/)
      match && match[0]
    end
    module_function :base_service_url
    
    def detect_ticketing_service(service)
      # try to find the service in the valid_services list
      # if loosely_matched_services is true, try to match the base url of the service to one in the valid_services list
      # if still no luck, check if there is a default_redirect_url that we can use
      @service||= service
      @ticketing_service||= valid_services.detect{|s| s == @service } || 
        (settings[:loosely_match_services] == true && valid_services.detect{|s| base_service_url(s) == base_service_url(@service)})
      if !@ticketing_service && settings[:default_redirect_url] && settings[:default_redirect_url][Rails.env]
        # try to set it to the default_service
        @ticketing_service = valid_services.detect{|s| base_service_url(s) == base_service_url(settings[:default_redirect_url][Rails.env])}
        @default_redirect_url||= settings[:default_redirect_url][Rails.env]
      end
      @username||= params[:username].try(:strip)
      @password||= params[:password]
      @lt||= params['lt']
    end
    module_function :detect_ticketing_service
    
    def cas_login
      if valid_credentials?
        # 3.6 (ticket-granting cookie)
        tgt = generate_ticket_granting_ticket(ticket_username, @extra_attributes)
        response.set_cookie('tgt', tgt.to_s)
        if @ticketing_service
          find_or_generate_service_tickets(ticket_username, tgt)
          @st = @service_tickets[@ticketing_service]
          @service_with_ticket = @service.blank? ? service_uri_with_ticket(@default_redirect_url, @st) : service_uri_with_ticket(@service, @st)
        end
        true
      else
        false
      end
    end
    module_function :cas_login
    
    # Initializes authenticator, returns true / false depending on if user credentials are accurate
    def valid_credentials?
      detect_ticketing_service(params[:service])
      @extra_attributes = {}
      # Should probably be moved out of the request cycle and into an after init hook on the engine

      credentials = { :username => @username,
                      :password => @password,
                      :service  => @service,
                      :request  => @env
                    }
      @user = authenticator.find_user(credentials) || authenticator.find_user(:username => session[:username])
      valid = ((@user == @ticketed_user) || authenticator.validate(credentials))# || !!@user
      if valid
        authenticator.extra_attributes_to_extract.each do |attr|
          @extra_attributes[attr] = @user.send(attr)
        end
      end
      return valid
    end
    module_function :valid_credentials?
    
    protected

    def ticket_username
      # Store this into someticket.username
      # It will get used to find users in client apps
      user = @user || @ticketed_user
      @cas_client_username = user.send(settings["client_app_user_field"]) if settings["client_app_user_field"].present? && !!user
      @cas_client_username || @username
    end
    
    def ticketed_user(ticket)
      # Find the SSO's instance of the user
      @ticketed_user ||= authenticator.find_user_from_ticket(ticket)
    end

    def authenticator
      unless @authenticator
        auth_settings = Cassy.config["authenticator"]
        @authenticator ||= auth_settings["class"].constantize
        @authenticator.configure(auth_settings)
      end
      @authenticator
    end

  end

end
