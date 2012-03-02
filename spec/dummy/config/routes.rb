# Placeholder for dummy routes
Rails.application.routes.draw do
  root :to => "fake#index"
  match '/another_page', :to => "fake#another_page"
  cassy
end