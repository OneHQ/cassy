require "grape"
module Cassy
  class API::Resource::TicketGrantingTickets < Grape::API
    resource :tickets do
      desc "Create a ticket_granting_ticket"
      post do
        if valid_credentials?
          @hostname = env['HTTP_X_FORWARDED_FOR'] || env['REMOTE_HOST'] || env['REMOTE_ADDR']
          @ticket = Cassy::TicketGrantingTicket.generate("#{ticket_username}-api", @extra_attributes, @hostname)
          Rails.logger.debug "Created auth token ticket '#{@ticket.ticket}'"
          present @ticket, with: Cassy::API::Entity::TicketGrantingTicket
        else
          error! "Invalid Credentials", 400
        end
      end

      desc "Request a service_ticket"
      post ":id" do
        tgt, error = TicketGrantingTicket.validate(params[:id])
        if tgt
          @hostname = env['HTTP_X_FORWARDED_FOR'] || env['REMOTE_HOST'] || env['REMOTE_ADDR']
          @ticket = ServiceTicket.generate(params[:service], tgt.username, tgt, @hostname)
          present @ticket, with: Cassy::API::Entity::ServiceTicket
        else
          error! "Invalid ticket or service", 400
        end
      end

      delete ":id" do
        tgt, error = TicketGrantingTicket.validate(params[:id])
        tgt.destroy_and_logout_all_service_tickets if tgt
        return ""
      end
    end
  end
end
