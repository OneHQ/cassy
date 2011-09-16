module Cassy
  class SessionsController < ApplicationController
    include Cassy::Utils
    include Cassy::CAS


    def new
      # optional params
      @service = clean_service_url(params['service'])
      @renew = params['renew']
      @gateway = params['gateway'] == 'true' || params['gateway'] == '1'
      if tgc = request.cookies['tgt']
        tgt, tgt_error = validate_ticket_granting_ticket(tgc)
      end

      if tgt and !tgt_error
        flash.now[:notice] = "You are currently logged in as '%s'. If this is not you, please log in below." % ticketed_user(tgt)[settings[:username_field]]
      end

      if params['redirection_loop_intercepted']
        flash.now[:error] = "The client and server are unable to negotiate authentication. Please try logging in again later."
      end
      
        
      begin
        if @service
          if @ticketed_user && valid_credentials?
            cas_login     
            redirect_to_url = @service_with_ticket
          elsif !@renew && tgt && !tgt_error
            find_or_generate_service_tickets(ticket_username, tgt)
            st = @service_tickets[@service]
            redirect_to_url = service_uri_with_ticket(@service, st)
          elsif @gateway
            redirect_to_url = @service
          end
          redirect_to redirect_to_url, :status => 303 if redirect_to_url# response code 303 means "See Other" (see Appendix B in CAS Protocol spec) 

        elsif @gateway
          flash.now[:error] = "The server cannot fulfill this gateway request because no service parameter was given."
        end
      rescue URI::InvalidURIError
        flash.now[:error] = "The target service your browser supplied appears to be invalid. Please contact your system administrator for help."
      end

      @lt = generate_login_ticket.ticket
    end
    
    def create
      setup_from_params!

      if error = validate_login_ticket(@lt)
        flash.now[:error] = error
        @lt = generate_login_ticket.ticket
        render(:new, :status => 500) and return
      end
      
      # generate another login ticket to allow for re-submitting the form after a post
      @lt = generate_login_ticket.ticket

      logger.debug("Logging in with username: #{@username}, lt: #{@lt}, service: #{@service}, auth: #{settings[:auth].inspect}")

      begin
        if cas_login
          begin
            if @service.blank?
              flash.now[:notice] = "You have successfully logged in."
              render :new
            else
              redirect_to @service_with_ticket, :status => 303 if @service_with_ticket# response code 303 means "See Other" (see Appendix B in CAS Protocol spec)
            end
          rescue URI::InvalidURIError
            flash.now[:error] = "The target service your browser supplied appears to be invalid. Please contact your system administrator for help."
          end
        else
          incorrect_credentials!
        end
      rescue Cassy::AuthenticatorError => e
        logger.error(e)
        # generate another login ticket to allow for re-submitting the form
        @lt = generate_login_ticket.ticket
        flash[:error] = e.to_s
        render :status => 401
      end
    end
    
    def destroy
      # The behaviour here is somewhat non-standard. Rather than showing just a blank
      # "logout" page, we take the user back to the login page with a "you have been logged out"
      # message, allowing for an opportunity to immediately log back in. This makes it
      # easier for the user to log out and log in as someone else.
      @service = clean_service_url(params['service'] || params['destination'])
      @continue_url = params['url']

      @gateway = params['gateway'] == 'true' || params['gateway'] == '1'

      tgt = Cassy::TicketGrantingTicket.find_by_ticket(request.cookies['tgt'])

      response.delete_cookie 'tgt'
      
      if tgt
        Cassy::TicketGrantingTicket.transaction do
          pgts = Cassy::ProxyGrantingTicket.find(:all,
            :conditions => [ActiveRecord::Base.connection.quote_table_name(Cassy::ServiceTicket.table_name)+".username = ?", tgt.username],
            :include => :service_ticket)
          pgts.each do |pgt|
            pgt.destroy
          end

          tgt.destroy
        end

        # $LOG.info("User '#{tgt.username}' logged out.")
      else
        # $LOG.warn("User tried to log out without a valid ticket-granting ticket.")
      end
       
      flash[:notice] = "You have successfully logged out."
      @lt = generate_login_ticket

      if @gateway && @service
        redirect_to @service, :status => 303
      else
        # TODO: Do not hardcode "/users/service"
        redirect_to "/cas/login?service=#{@service}/users/service"
      end
    end
    
    def service_validate
      # required
      @service = clean_service_url(params['service'])
      @ticket = params['ticket']
      # optional
      @renew = params['renew']

      st, @error = validate_service_ticket(@service, @ticket)
      @success = st && !@error
      if @success
        @username = ticketed_user(st).send(settings[:client_app_user_field])
        if @pgt_url
          pgt = generate_proxy_granting_ticket(@pgt_url, st)
          @pgtiou = pgt.iou if pgt
        end
        @extra_attributes = st.granted_by_tgt.extra_attributes || {}
      end

      status = response_status_from_error(@error) if @error

      render :proxy_validate, :layout => false, :status => status || 200
    end
    
    def proxy_validate

      # required
      @service = clean_service_url(params['service'])
      @ticket = params['ticket']
      # optional
      @pgt_url = params['pgtUrl']
      @renew = params['renew']

      @proxies = []

      t, @error = validate_proxy_ticket(@service, @ticket)
      @success = t && !@error

      @extra_attributes = {}
      if @success
        @username = ticketed_user(t)[settings[:cas_app_user_filed]]

        if t.kind_of? Cassy::ProxyTicket
          @proxies << t.granted_by_pgt.service_ticket.service
        end

        if @pgt_url
          pgt = generate_proxy_granting_ticket(@pgt_url, t)
          @pgtiou = pgt.iou if pgt
        end

        @extra_attributes = t.granted_by_tgt.extra_attributes || {}
      end

      status = response_status_from_error(@error) if @error

      render :proxy_validate, :layout => false, :status => status || 200
      
    end
    
    private
    
    def response_status_from_error(error)
      case error.code.to_s
      when /^INVALID_/, 'BAD_PGT'
        422
      when 'INTERNAL_ERROR'
        500
      else
        500
      end
    end
    
    def setup_from_params!
      # 2.2.1 (optional)
      @service = clean_service_url(params['service'])

      # 2.2.2 (required)
      @username = params[:username].try(:strip)
      @password = params[:password]
      @lt = params['lt']
    end

    # Initializes authenticator, returns true / false depending on if user credentials are accurate
    def valid_credentials?
      setup_from_params!
      @extra_attributes = {}
      # Should probably be moved out of the request cycle and into an after init hook on the engine

      credentials = { :username => @username,
                      :password => @password,
                      :service  => @service,
                      :request  => @env
                    }

      @user = authenticator.find_user(credentials)
      valid = ((@user == @ticketed_user) || authenticator.validate(credentials))  && !!@user
      if valid
        authenticator.extra_attributes_to_extract.each do |attr|
          @extra_attributes[attr] = @user.send(attr)
        end
        #session["cassy.user.key"]=@username
      end
      
      return valid
    end
    
    def incorrect_credentials!
      @lt = generate_login_ticket.ticket
      flash.now[:error] = "Incorrect username or password."
      render :new, :status => 401
    end

    protected
    def valid_services
      @valid_services || settings[:service_list]
    end

    def find_or_generate_service_tickets(username, tgt)
      @service_tickets={}
      valid_services.each do |service|
        @service_tickets[service] = generate_service_ticket(service, username, tgt)
      end
    end

    def cas_login
      if valid_credentials?
        # 3.6 (ticket-granting cookie)
        tgt = generate_ticket_granting_ticket(ticket_username, @extra_attributes)
        response.set_cookie('tgt', tgt.to_s)
        
        unless @service.blank?
          find_or_generate_service_tickets(ticket_username, tgt)
          @st = @service_tickets[@service]
          @service_with_ticket = service_uri_with_ticket(@service, @st)
        end

        true
      else
        false
      end
    end

    def ticket_username
      # Store this into someticket.username
      # It will get used to find users in client apps
      user = @user || @ticketed_user
      @cas_client_username = user[settings["client_app_user_field"]] if settings["client_app_user_field"].present? && !!user
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
