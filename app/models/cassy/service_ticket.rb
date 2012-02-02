module Cassy
  class ServiceTicket < ActiveRecord::Base
	include Cassy::Ticket

    set_table_name 'casserver_st'

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

    def matches_service?(service)
      # check for a matching service in the service list
      # then check for a matching service with a wildcard subdomain
      Cassy::CAS.clean_service_url(self.service) == Cassy::CAS.clean_service_url(service) ||
        Cassy::CAS.clean_service_url(Cassy::CAS.conform_uri(self.service)) == Cassy::CAS.clean_service_url(Cassy::CAS.conform_uri(service))
    end
  end
end