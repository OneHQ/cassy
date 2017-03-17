require "grape"
module Cassy
  class API < Grape::API
    helpers Cassy::CAS

    format :json

    mount Cassy::API::Resource::TicketGrantingTickets
  end
end
