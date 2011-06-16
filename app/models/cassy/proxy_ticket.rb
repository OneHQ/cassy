module Cassy
  class ProxyTicket < ServiceTicket
    belongs_to :granted_by_pgt,
      :class_name => 'Cassy::ProxyGrantingTicket',
      :foreign_key => :granted_by_pgt_id
  end
end