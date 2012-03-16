require 'spec_helper'

describe Cassy::ServiceTicket do

  before do
    Cassy::ServiceTicket.delete_all
    @ticket_granting_ticket = Cassy::TicketGrantingTicket.create(:ticket => "TGT-12345678900987654321", :created_on => Time.now, :username => "1", :client_hostname => "http://sss.something.com", :extra_attributes => {})
    @service_ticket = Cassy::ServiceTicket.create!(:ticket => "ST-12345678901234567890", :consumed => false, :client_hostname => "http://sso.something.com", :granted_by_tgt => @ticket_granting_ticket, :service => "http://members.something.com", :username => "1")
  end
  
  it "should validate" do
    Cassy::ServiceTicket.validate("http://members.something.com","ST-12345678901234567890").should == [@service_ticket, "Ticket 'ST-12345678901234567890' for 'http://members.something.com' for user '1' successfully validted."]    
  end
  
  it "should not validate if the ticket has already been consumed" do
    @service_ticket.consume!
    Cassy::ServiceTicket.validate("http://members.something.com","ST-12345678901234567890").should == [nil, "Ticket ST-12345678901234567890 has already been consumed."]
  end

  it "should not validate if the ticket is too old" do
    @service_ticket.created_on = Time.now-7201
    @service_ticket.save!
    Cassy::ServiceTicket.validate("http://members.something.com", "ST-12345678901234567890").should == [nil, "Ticket ST-12345678901234567890 has expired. Please try again."]
  end
  
  it "should not validate if the ticket is invalid" do
    Cassy::ServiceTicket.validate("http://members.something.com", "ST-09876543210987654321").should == [nil, "Ticket 'ST-09876543210987654321' not recognized."]
  end
  
end
