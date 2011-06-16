module Cassy
  class LoginTicket < Ticket
    set_table_name 'casserver_lt'
    include Consumable
  end
end