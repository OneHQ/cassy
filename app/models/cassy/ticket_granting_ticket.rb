module Cassy
  class TicketGrantingTicket < ActiveRecord::Base
	include Cassy::Ticket
    set_table_name 'casserver_tgt'

    serialize :extra_attributes

    has_many :granted_service_tickets,
      :class_name => 'Cassy::ServiceTicket',
      :foreign_key => :granted_by_tgt_id
  end
end