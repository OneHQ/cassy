module Cassy
  class LoginTicket < ActiveRecord::Base
  	include Cassy::Ticket
    set_table_name 'casserver_lt'
    include Consumable
    
    def self.validate(ticket="invalid")
      ticket_in_database = LoginTicket.find_by_ticket(ticket)
      if ticket_in_database
        if ticket_in_database.consumed?
          {:valid => false, :error => "The login ticket you provided has already been used up. Please try logging in again."}
        elsif Time.now - ticket_in_database.created_on >= Cassy.config[:maximum_unused_login_ticket_lifetime]
          {:valid => false, :error => "You took too long to enter your credentials. Please try again."}
        else
          ticket_in_database.consume! && {:valid => true}
        end
      else
        {:valid => false, :error => "The login ticket you provided is invalid. There may be a problem with the authentication system."}
      end
    end
        
  end
end