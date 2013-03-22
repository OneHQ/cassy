module Cassy
  class ServiceTicket < ActiveRecord::Base
	include Cassy::Ticket

    self.table_name = 'casserver_st'

    # Need to confirm the before_save function is actually needed. Seems that every
    # instance of this type (in 130000 rows) has the same value of "Cassy::ServiceTicket"
    # but before I nuke it, need to include tests.  This error came up after migrating
    # from Rails 3.1 to 3.2, inheritence columns are not auto filled unless the parent
    # model is not an abstract class, see commit e425aec66acc909e68992616fb2bfc4ce6d2f629
    # where the Ticket model was changed to a module.
    before_save :set_type_column
    def set_type_column
      self.type = "Cassy::ServiceTicket"
    end

    include Consumable

    belongs_to :granted_by_tgt, :class_name => 'Cassy::TicketGrantingTicket', :foreign_key => :granted_by_tgt_id
    has_one :proxy_granting_ticket, :foreign_key => :created_by_st_id
    
    def self.validate(service, ticket, allow_proxy_tickets = false)
      logger.debug "Validating service ticket '#{ticket}' for service '#{service}'"

      if service.nil?
        logger.warn "Service not provided to validate service ticket"
        [nil, "Ticket or service parameter was missing in the request"]
      elsif st = Cassy::ServiceTicket.find_by_ticket(ticket)
        if st.consumed?
          logger.warn "Ticket #{ticket} has already been used"
          [nil, "Ticket #{ticket} has already been consumed."]
        elsif st.kind_of?(Cassy::ProxyTicket) && !allow_proxy_tickets
          logger.warn "Ticket '#{ticket}' is a proxy ticket, but only service tickets are allowed here."
          [nil, "Ticket '#{ticket}' is a proxy ticket, but only service tickets are allowed here."]
        elsif Time.now - st.created_on > Cassy.config[:maximum_unused_service_ticket_lifetime]
          logger.warn "Ticket #{ticket} has expired."
          [nil, "Ticket #{ticket} has expired. Please try again."]
        elsif !st.matches_service? service
          logger.warn "The ticket #{ticket} belonging to user #{st.username} is valid but the requested service #{service} doesn't match the service #{st.service} associated with the ticket."
          [nil, "The ticket #{ticket} belonging to user #{st.username} is valid but the requested service #{service} doesn't match the service #{st.service} associated with the ticket."]
        else
          st.consume!
          logger.info("Ticket '#{ticket}' for service '#{service}' for user '#{st.username}' successfully validated.")
          [st, "Ticket '#{ticket}' for '#{service}' for user '#{st.username}' successfully validted."]
        end
      else
        logger.warn "Ticket '#{ticket}' not recognized."
        [nil, "Ticket '#{ticket}' not recognized."]
      end
    end
    

    def matches_service?(service)
      if Cassy.config[:loosely_match_services] == true
        Cassy::CAS.base_service_url(self.service) == Cassy::CAS.base_service_url(service)
      else
        Cassy::CAS.clean_service_url(self.service) == Cassy::CAS.clean_service_url(service)
      end
    end
    
    # Takes an existing ServiceTicket object (presumably pulled from the database)
    # and sends a POST with logout information to the service that the ticket
    # was generated for.
    #
    # This makes possible the "single sign-out" functionality added in CAS 3.1.
    # See http://www.ja-sig.org/wiki/display/CASUM/Single+Sign+Out
    def send_logout_notification
      uri = URI.parse(self.service)
      uri.path = '/' if uri.path.empty?
      begin
        response = Net::HTTP.post_form(uri, self.logout_notification_message)
        if response.kind_of? Net::HTTPSuccess
          logger.debug "Logout notification successfully posted to #{self.service.inspect}."
          return true
        else
          logger.warn "Service #{self.service.inspect} responded to logout notification with code '#{response.code}'!"
          return false
        end
      rescue Exception => e
        logger.warn "Failed to send logout notification to service #{self.service.inspect} due to #{e}"
        return false
      end
    end
    
    # XML to be posted when using single sign out
    def logout_notification_message
      time = Time.now
      rand = Cassy::Utils.random_string
      {'logoutRequest' => (%{<samlp:LogoutRequest ID="#{rand}" Version="2.0" IssueInstant="#{time.rfc2822}">
        <saml:NameID></saml:NameID>
        <samlp:SessionIndex>#{self.ticket}</samlp:SessionIndex>
        </samlp:LogoutRequest>})}       
    end
    
    # Try to find an existing service ticket for the given user and service
    def self.find_or_generate(service, username, tgt, hostname)
      st = tgt.granted_service_tickets.where(:service => service).where("created_on > ?", Time.now - Cassy.config[:maximum_session_lifetime]).order("created_on DESC").first
      st || self.generate(service, username, tgt, hostname)
    end
    
    def self.generate(service, username, tgt, hostname)
      st = ServiceTicket.new
      st.ticket = "ST-" + Cassy::Utils.random_string
      st.service = service
      st.username = username
      st.granted_by_tgt_id = tgt.id
      st.client_hostname = hostname
      st.save!
      logger.debug("Generated service ticket '#{st.ticket}' for service '#{st.service}'" +
        " for user '#{st.username}' at '#{st.client_hostname}'")
      st
    end
    
  end
end
