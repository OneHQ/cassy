require 'grape-entity'
module Cassy
  class API::Entity::TicketGrantingTicket < Grape::Entity
    expose :ticket
  end
end
