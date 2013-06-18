module Cassy
  class SessionsController < ApplicationController
    include Cassy::Utils
    include Cassy::CAS

    def new
      detect_ticketing_service(params[:service])
      
      @renew = params['renew']
      @gateway = params['gateway'] == 'true' || params['gateway'] == '1'
      @hostname = env['HTTP_X_FORWARDED_FOR'] || env['REMOTE_HOST'] || env['REMOTE_ADDR']
      @tgt, tgt_error = Cassy::TicketGrantingTicket.validate(request.cookies['tgt'])
      if @tgt
        flash.now[:notice] = "You are currently logged in as '%s'." % ticketed_user(@tgt).send(settings[:username_field])
      end

      if params['redirection_loop_intercepted']
        flash.now[:error] = "The client and server are unable to negotiate authentication. Please try logging in again later."
      end
      
      if @service
        if @ticketed_user && cas_login
          redirect_to @service_with_ticket
        elsif @existing_ticket_for_service
          redirect_to logout_url
        elsif !@renew && @tgt && !tgt_error
          find_or_generate_service_tickets(ticket_username, @tgt)
          st = @service_tickets[@ticketing_service]
          redirect_to service_uri_with_ticket(@ticketing_service, st)
        elsif @gateway
          redirect_to @gateway
        end
      elsif @gateway
        flash.now[:error] = "The server cannot fulfill this gateway request because no service parameter was given."
      end

      @lt = generate_login_ticket.ticket
    end
    
    def create
      @lt = generate_login_ticket.ticket # in case the login isn't successful, another ticket needs to be generated for the next attempt at login
      detect_ticketing_service(params[:service])
      @hostname = env['HTTP_X_FORWARDED_FOR'] || env['REMOTE_HOST'] || env['REMOTE_ADDR']
      consume_ticket = Cassy::LoginTicket.validate(@lt)
      if !consume_ticket[:valid]
        flash.now[:error] = consume_ticket[:error]
        @lt = generate_login_ticket.ticket
        render(:new, :status => 500) and return
      end

      logger.debug("Logging in with username: #{@username}, lt: #{@lt}, service: #{@service}, auth: #{settings[:auth].inspect}")
      if cas_login
        if @service_with_ticket
          redirect_to after_sign_in_path_for(@service_with_ticket)
        else
          flash.now[:notice] = "You have successfully logged in."
          render :new
        end        
      else
        incorrect_credentials!
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
          if Cassy.config[:enable_single_sign_out]
            tgt.granted_service_tickets.each do |st|
              st.send_logout_notification
              st.destroy
            end
          end
          tgt.destroy
        end
      end
       
      flash[:notice] = "You have successfully logged out."
      @lt = generate_login_ticket

      if @gateway && @service
        redirect_to @service, :status => 303
      else
        redirect_to :action => :new, :service => @service
      end
    end
    
    def service_validate
      # takes a params[:service] and a params[:ticket] and validates them
      
      # required
      @service = clean_service_url(params['service'])
      @ticket = params['ticket']
      # optional
      @renew = params['renew']
      @pgt_url = params['pgtUrl']

      @service_ticket, @error = Cassy::ServiceTicket.validate(@service, @ticket)
      if @service_ticket
        @username = ticketed_user(@service_ticket).send(settings[:client_app_user_field])
        if @pgt_url
          pgt = generate_proxy_granting_ticket(@pgt_url, @service_ticket)
          @pgtiou = pgt.iou if pgt
        end
        @extra_attributes = @service_ticket.granted_by_tgt ? @service_ticket.granted_by_tgt.extra_attributes : {}
      end
      render :proxy_validate, :layout => false, :status => @service_ticket ? 200 : 422
    end
    
    def proxy_validate
      # required
      @service = clean_service_url(params['service'])
      @ticket = params['ticket']
      # optional
      @pgt_url = params['pgtUrl']
      @renew = params['renew']

      @proxies = []

      @service_ticket, @error = Cassy::ServiceTicket.validate(@service, @ticket)
      @extra_attributes = {}
      if @service_ticket
        @username = ticketed_user(@service_ticket).send(settings[:client_app_user_field])

        if @service_ticket.kind_of? Cassy::ProxyTicket
          @proxies << t.granted_by_pgt.service_ticket.service
        end

        if @pgt_url
          pgt = generate_proxy_granting_ticket(@pgt_url, @service_ticket)
          @pgtiou = pgt.iou if pgt
        end

        @extra_attributes = @service_ticket.granted_by_tgt ? @service_ticket.granted_by_tgt.extra_attributes : {}
      end

      render :proxy_validate, :layout => false, :status => @service_ticket ? 200 : 422
      
    end
    
    private
    
    def incorrect_credentials!
      @lt = generate_login_ticket.ticket
      flash.now[:error] = "Incorrect username or password."
      render :new, :status => 401
    end

  end
end
