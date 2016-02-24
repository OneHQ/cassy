require 'grape-entity'
module Cassy
  class API::Entity::ServiceTicket < Grape::Entity
    expose :ticket
  end
end
