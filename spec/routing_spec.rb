require 'spec_helper'

describe "routing" do
  before(:all) do
    define_devise_schema
  end
  
  before do
    @valid_email = "test_user@example.com"
    @valid_username = "bobbles"
    @valid_password = "password"
    
    User.create!(:email => @valid_email, :password => @valid_password, :username => @valid_username, :full_name => "Valid User")
    
    @target_service = 'http://my.app.test'
    Cassy::Engine.config.configuration_file = File.dirname(__FILE__) + "/default_config.yml"
    Cassy::Engine.config.configuration[:authenticator][:class] = "Cassy::Authenticators::Devise"
    Cassy::Engine.config.configuration[:username_label] = "Email"
    Cassy::Engine.config.configuration[:username_field] = "email"
    
    # Override routes to point to application's SessionsController
    Rails.application.routes.clear!
    Rails.application.routes.draw do
      cassy :controllers => { :sessions => "sessions" }
    end
  end
  
  it "uses the application's sessions controller" do
    visit "/cas/login"

    fill_in 'Email', :with => @valid_email
    fill_in 'Password', :with => @valid_password
    click_button 'Login'
    page.should have_content("You have logged into Dummy.")
  end
end