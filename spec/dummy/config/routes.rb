# Placeholder for dummy routes
Rails.application.routes.draw do
  root :to => "fake#index"
  get '/another_page', :to => "fake#another_page"
  cassy
end