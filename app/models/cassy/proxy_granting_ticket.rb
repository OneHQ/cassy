module Cassy
  class ProxyGrantingTicket < ActiveRecord::Base
	include Cassy::Ticket
    self.table_name = 'casserver_pgt'
    belongs_to :service_ticket
    has_many :granted_proxy_tickets,
      :class_name => 'Cassy::ProxyTicket',
      :foreign_key => :granted_by_pgt_id
  end
  
  def self.validate(ticket)
    if ticket.nil?
      error = Error.new(:INVALID_REQUEST, "pgt parameter was missing in the request.")
      logger.warn("#{error.code} - #{error.message}")
    elsif pgt = ProxyGrantingTicket.find_by_ticket(ticket)
      if pgt.service_ticket
        logger.info("Proxy granting ticket '#{ticket}' belonging to user '#{pgt.service_ticket.username}' successfully validated.")
      else
        error = Error.new(:INTERNAL_ERROR, "Proxy granting ticket '#{ticket}' is not associated with a service ticket.")
        logger.error("#{error.code} - #{error.message}")
      end
    else
      error = Error.new(:BAD_PGT, "Invalid proxy granting ticket '#{ticket}' (no matching ticket found in the database).")
      logger.warn("#{error.code} - #{error.message}")
    end

    [pgt, error]
  end
  
end