require 'spec_helper'

VALID_USERNAME = 'spec_user'
VALID_PASSWORD = 'spec_password'

ATTACK_USERNAME = '%3E%22%27%3E%3Cscript%3Ealert%2826%29%3C%2Fscript%3E&password=%3E%22%27%3E%3Cscript%3Ealert%2826%29%3C%2Fscript%3E&lt=%3E%22%27%3E%3Cscript%3Ealert%2826%29%3C%2Fscript%3E&service=%3E%22%27%3E%3Cscript%3Ealert%2826%29%3C%2Fscript%3E'
INVALID_PASSWORD = 'invalid_password'

describe Cassy::Authenticators::Test do

  before do
    @target_service = 'http://my.app.test'
    config = File.dirname(__FILE__) + "/../default_config.yml"
    Cassy::Engine.config.configuration = HashWithIndifferentAccess.new(YAML.load_file(config))
  end

  describe "/cas/login" do

    it "logs in successfully with valid username and password without a target service" do
      visit "/cas/login"
      fill_in 'username', :with => VALID_USERNAME
      fill_in 'Password', :with => VALID_PASSWORD
      click_button 'Login'
      page.should have_content("You have successfully logged in")

    end

    it "fails to log in with invalid password" do
      visit "/cas/login"
      fill_in 'username', :with => VALID_USERNAME
      fill_in 'Password', :with => INVALID_PASSWORD
      click_button 'Login'

      page.should have_content("Incorrect username or password")
    end

    it "logs in successfully with valid username and password and redirects to target service" do
      visit "/cas/login?service="+CGI.escape(@target_service)
      fill_in 'username', :with => VALID_USERNAME
      fill_in 'password', :with => VALID_PASSWORD

      click_button 'Login'

      page.current_url.should =~ /^#{Regexp.escape(@target_service)}\/?\?ticket=ST\-[1-9rA-Z]+/
    end

    it "preserves target service after invalid login" do
      visit "/cas/login?service="+CGI.escape(@target_service)

      fill_in 'username', :with => VALID_USERNAME
      fill_in 'password', :with => INVALID_PASSWORD
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

      fill_in 'username', :with => VALID_USERNAME
      fill_in 'Password', :with => VALID_PASSWORD

      click_button 'Login'

      page.current_url.should =~ /^#{Regexp.escape(@target_service)}\/?\?ticket=ST\-[1-9rA-Z]+/
      @ticket = page.current_url.match(/ticket=(.*)$/)[1]
    end

    it "should have extra attributes in proper format" do
      Cassy::Engine.config.configuration[:extra_attributes] = [{ :user => :full_name }]
      visit "/cas/serviceValidate?service=#{CGI.escape(@target_service)}&ticket=#{@ticket}"
      page.body.should match("<full_name>Example User</full_name>")
    end
  end
end
