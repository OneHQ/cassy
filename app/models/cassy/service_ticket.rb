module Cassy
  class ServiceTicket < Ticket
    set_table_name 'casserver_st'
    include Consumable

    belongs_to :granted_by_tgt, :class_name => 'Cassy::TicketGrantingTicket', :foreign_key => :granted_by_tgt_id
    has_one :proxy_granting_ticket, :foreign_key => :created_by_st_id

    def matches_service?(service)
      # check for a matching service in the service list
      # then check for a matching service with a wildcard subdomain
      Cassy::CAS.clean_service_url(self.service) == Cassy::CAS.clean_service_url(service) ||
        Cassy::CAS.clean_service_url(Cassy::CAS.conform_uri(self.service)) == Cassy::CAS.clean_service_url(Cassy::CAS.conform_uri(service))
    end
  end
end