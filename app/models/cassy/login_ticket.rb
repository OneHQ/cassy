module Cassy
  class LoginTicket < ActiveRecord::Base
  	include Cassy::Ticket
    set_table_name 'casserver_lt'
    include Consumable
  end
end