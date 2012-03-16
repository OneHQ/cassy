module Cassy
  class TicketGrantingTicket < ActiveRecord::Base
  	include Cassy::Ticket
    set_table_name 'casserver_tgt'

    serialize :extra_attributes

    has_many :granted_service_tickets,
      :class_name => 'Cassy::ServiceTicket',
      :foreign_key => :granted_by_tgt_id
      
      
    def self.validate(ticket)
      if ticket.nil?
        [nil, "No ticket provided."]
      elsif tgt = TicketGrantingTicket.find_by_ticket(ticket)
        if Cassy.config[:maximum_session_lifetime] && Time.now - Cassy.config[:maximum_session_lifetime] > tgt.created_on
  	      tgt.destroy
  	      [nil, "Ticket TGT-12345678901234567890 has expired. Please log in again."]
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
    def self.generate(username, extra_attributes={}, hostname)
      # 3.6 (ticket granting cookie/ticket)
      tgt = Cassy::TicketGrantingTicket.new
      tgt.ticket = "TGC-" + Cassy::Utils.random_string
      tgt.username = username
      tgt.extra_attributes = extra_attributes
      tgt.client_hostname = hostname
      tgt.save!
      tgt
    end
      
  end
end