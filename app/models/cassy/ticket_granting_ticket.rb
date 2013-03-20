module Cassy
  class TicketGrantingTicket < ActiveRecord::Base
  	include Cassy::Ticket
    self.table_name = 'casserver_tgt'

    serialize :extra_attributes

    has_many :granted_service_tickets,
      :class_name => 'Cassy::ServiceTicket',
      :foreign_key => :granted_by_tgt_id,
      :dependent => :destroy
      
      
    def self.validate(ticket)
      if ticket.nil?
        [nil, "No ticket provided."]
      elsif tgt = TicketGrantingTicket.find_by_ticket(ticket)
        if Cassy.config[:maximum_session_lifetime] && Time.now - Cassy.config[:maximum_session_lifetime] > tgt.created_on
  	      tgt.destroy
  	      [nil, "Ticket TGT-12345678901234567890 has expired. Please log in again."]
        elsif Cassy.config[:single_sign_out] && Cassy.config[:no_concurrent_sessions] && tgt.not_the_latest_for_this_user?
          tgt.destroy
          [nil, "This ticket is not valid bacuse there is a more recent session for user '#{tgt.username}'"]
        else
          [tgt, "Ticket granting ticket '#{ticket}' for user '#{tgt.username}' successfully validated."]
        end
      else
        [nil, "Ticket '#{ticket}' not recognized."]
      end
    end
    
    # Creates a TicketGrantingTicket for the given username. This is done when the user logs in
    # for the first time to establish their SSO session (after their credentials have been validated).
    #
    # The optional 'extra_attributes' parameter takes a hash of additional attributes
    # that will be sent along with the username in the CAS response to subsequent
    # validation requests from clients.
    #
    # If the no_concurrent_session option is set to true, this will also find the previous ticket
    # and call destroy_and_logout_all_service_tickets to remove the associated service_tickets.
    def self.generate(username, extra_attributes={}, hostname)
      # 3.6 (ticket granting cookie/ticket)
      tgt = Cassy::TicketGrantingTicket.new
      tgt.ticket = "TGC-" + Cassy::Utils.random_string
      tgt.username = username
      tgt.extra_attributes = extra_attributes
      tgt.client_hostname = hostname
      tgt.save!
      if Cassy.config[:enable_single_sign_out] && Cassy.config[:no_concurrent_sessions] == true && tgt.previous_ticket
        tgt.previous_ticket.destroy_and_logout_all_service_tickets
      end
      tgt
    end
    
    # Returns the users previous ticket_granting_ticket
    def previous_ticket
      Cassy::TicketGrantingTicket.where(:username => username.to_s).where("id <> ?",self.id).where("created_on > ?", Time.now - Cassy.config[:maximum_session_lifetime]).order("created_on DESC").first
    end
    
    # Returns true if the ticket is not the most recent ticket granting ticket for that username
    def not_the_latest_for_this_user?
      Cassy::TicketGrantingTicket.where(:username => username).where("created_on > ? AND id <> ?",created_on,self.id).any?
    end
    
    # If enable_single_sign_out is true, sends a logout notification to each service before destroying the ticket
    def destroy_and_logout_all_service_tickets
      if Cassy.config[:enable_single_sign_out]
        granted_service_tickets.each do |st|
          st.send_logout_notification
        end
        destroy
      else
        raise "Single Sign Out is not enabled for Cassy. If you want to enable it, add 'enable_single_sign_out: true' to the Cassy config file."
      end
    end
      
  end
end
