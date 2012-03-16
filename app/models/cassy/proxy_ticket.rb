module Cassy
  class ProxyTicket < ServiceTicket
    belongs_to :granted_by_pgt,
      :class_name => 'Cassy::ProxyGrantingTicket',
      :foreign_key => :granted_by_pgt_id
  end
  
  def validate(service, ticket)
    pt, error = Cassy::ServiceTicket.validate(service, ticket, true)

    if pt.kind_of?(Cassy::ProxyTicket) && !error
      if not pt.granted_by_pgt
        error = Error.new(:INTERNAL_ERROR, "Proxy ticket '#{pt}' belonging to user '#{pt.username}' is not associated with a proxy granting ticket.")
      elsif not pt.granted_by_pgt.service_ticket
        error = Error.new(:INTERNAL_ERROR, "Proxy granting ticket '#{pt.granted_by_pgt}'"+
          " (associated with proxy ticket '#{pt}' and belonging to user '#{pt.username}' is not associated with a service ticket.")
      end
    end

    [pt, error]
  end
  
end