require 'spec_helper'

describe Cassy::LoginTicket do

  before do
    Cassy::LoginTicket.delete_all
    @login_ticket = Cassy::LoginTicket.create(:ticket => "ST-12345678901234567890", :consumed => false, :client_hostname => "http://sso.something.com")
  end
  
  it "should validate" do
    Cassy::LoginTicket.validate("ST-12345678901234567890").should == {:valid => true}    
  end
  
  it "should not validate if the ticket has already been consumed" do
    @login_ticket.consume!
    Cassy::LoginTicket.validate("ST-12345678901234567890").should == {:valid => false, :error => "The login ticket you provided has already been used up. Please try logging in again."}
  end

  it "should not validate if the ticket is too old" do
    @login_ticket.created_on = Time.now-7201
    @login_ticket.save!
    Cassy::LoginTicket.validate("ST-12345678901234567890").should == {:valid => false, :error => "You took too long to enter your credentials. Please try again."}
  end
  
  it "should not validate if the ticket is invalid" do
    Cassy::LoginTicket.validate("ST-09876543210987654321").should == {:valid => false, :error => "The login ticket you provided is invalid. There may be a problem with the authentication system."}
  end
  
end
