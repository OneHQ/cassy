require 'spec_helper'
require 'rubygems'
require 'ruby-debug'

describe Cassy::Authenticators::Devise do
  before(:all) do
    define_devise_schema
  end

  before(:each) do
    @valid_email = "test_user@example.com"
    @valid_username = "bobbles"
    @valid_password = "password"

    @user = User.create!(:email => @valid_email, :password => @valid_password, :username => @valid_username, :full_name => "Valid User")

    @target_service = 'http://my.app.test'
    Cassy::Engine.config.configuration_file = File.dirname(__FILE__) + "/default_config.yml"
    Cassy::Engine.config.configuration[:authenticator][:class] = "Cassy::Authenticators::Devise"
    Cassy::Engine.config.configuration[:username_label] = "Email"
    Cassy::Engine.config.configuration[:username_field] = "email"
  end

  describe "/cas/login" do

    it "logs in successfully with valid email and password without a target service" do
      visit "/cas/login"

      fill_in 'Email',    :with => @valid_email
      fill_in 'Password', :with => @valid_password
      click_button 'Login'
      page.should have_content("You have successfully logged in")
    end

    it "logs in successfully with valid username and password without a target service" do
      Cassy::Engine.config.configuration[:username_label] = "Username"
      Cassy::Engine.config.configuration[:username_field] = "username"

      visit "/cas/login"

      fill_in 'Username', :with => @valid_username
      fill_in 'Password', :with => @valid_password
      click_button 'Login'
      page.should have_content("You have successfully logged in")
    end

    it "fails to log in with invalid password" do
      visit "/cas/login"
      fill_in 'Email', :with => @valid_email
      fill_in 'Password', :with => "not_the_password"
      click_button 'Login'

      page.should have_content("Incorrect username or password")
    end

    it "logs in successfully with valid username and password and redirects to target service" do
      visit "/cas/login?service="+CGI.escape(@target_service)

      fill_in 'Email', :with => @valid_email
      fill_in 'password', :with => @valid_password

      click_button 'Login'

      page.current_url.should =~ /^#{Regexp.escape(@target_service)}\/?\?ticket=ST\-[1-9rA-Z]+/
    end

    it "preserves target service after invalid login" do
      visit "/cas/login?service="+CGI.escape(@target_service)

      fill_in 'Email', :with => @valid_email
      fill_in 'password', :with => "not_the_password"
      click_button 'Login'

      page.should have_content("Incorrect username or password")
      page.should have_xpath('//input[@id="service"]', :value => @target_service)
    end

    it "allows a user to be disabled using the standard Devise :active_for_authentication? method" do
      visit "/cas/login?service="+CGI.escape(@target_service)

      @user.stub!(:active_for_authentication?).and_return(false)
      fill_in 'Email', :with => @valid_email
      fill_in 'password', :with => @valid_password
      click_button 'Login'

      page.should have_content("Incorrect username or password")
      page.should have_xpath('//input[@id="service"]', :value => @target_service)
    end

    it "is not vunerable to Cross Site Scripting" do
      visit '/cas/login?service=%22%2F%3E%3cscript%3ealert%2832%29%3c%2fscript%3e'
      page.should_not have_content("alert(32)")
      page.should_not have_xpath("//script")
      #page.should have_xpath("<script>alert(32)</script>")We
    end

  end # describe '/login'


  describe '/logout' do

    it "logs out successfully" do
      visit "/cas/logout"

      page.should have_content("You have successfully logged out")
    end

    it "logs out successfully and redirects to target service" do
      visit "/cas/logout?gateway=true&service="+CGI.escape(@target_service)

      page.current_url.should =~ /^#{Regexp.escape(@target_service)}\/?/
    end

  end # describe '/logout'

  describe "proxyValidate" do
    before do

      visit "/cas/login?service="+CGI.escape(@target_service)

      fill_in 'Email', :with => @valid_email
      fill_in 'Password', :with => @valid_password

      click_button 'Login'

      page.current_url.should =~ /^#{Regexp.escape(@target_service)}\/?\?ticket=ST\-[1-9rA-Z]+/
      @ticket = page.current_url.match(/ticket=(.*)$/)[1]
    end

    it "should have extra attributes in proper format" do
      visit "/cas/serviceValidate?service=#{CGI.escape(@target_service)}&ticket=#{@ticket}"
      page.body.should match("<full_name>Valid User</full_name>")
    end
  end

end
