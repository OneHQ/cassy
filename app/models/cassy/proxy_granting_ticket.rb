module Cassy
  class ProxyGrantingTicket < ActiveRecord::Base
	include Cassy::Ticket
    set_table_name 'casserver_pgt'
    belongs_to :service_ticket
    has_many :granted_proxy_tickets,
      :class_name => 'Cassy::ProxyTicket',
      :foreign_key => :granted_by_pgt_id
  end
end