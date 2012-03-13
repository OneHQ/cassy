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
        error = "No ticket granting ticket given."
        logger.debug error
      elsif tgt = TicketGrantingTicket.find_by_ticket(ticket)
        if Cassy.config[:maximum_session_lifetime] && Time.now - tgt.created_on > Cassy.config[:maximum_session_lifetime]
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
      
  end
end