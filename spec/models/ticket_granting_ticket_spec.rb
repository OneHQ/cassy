require 'spec_helper'

describe Cassy::TicketGrantingTicket do

  before do
    Cassy::TicketGrantingTicket.delete_all
    @ticket_granting_ticket = Cassy::TicketGrantingTicket.create(:ticket => "TGT-12345678900987654321", :created_on => Time.now, :username => "1", :client_hostname => "http://sss.something.com", :extra_attributes => {})
  end
  
  it "should validate" do
    Cassy::TicketGrantingTicket.validate("TGT-12345678900987654321").should == [@ticket_granting_ticket, "Ticket granting ticket 'TGT-12345678900987654321' for user '1' successfully validated."]    
  end

  it "should not validate if the ticket is too old" do
    @ticket_granting_ticket.created_on = Time.now-7201
    @ticket_granting_ticket.save!
    Cassy::TicketGrantingTicket.validate("TGT-12345678900987654321").should == [nil, "Ticket TGT-12345678901234567890 has expired. Please log in again."]
  end
  
  it "should not validate if the ticket is invalid" do
    Cassy::TicketGrantingTicket.validate("TGT-09876543210987654321").should == [nil, "Ticket 'TGT-09876543210987654321' not recognized."]
  end
  
  context "single sign out" do
  
    before do
      @service_ticket = Cassy::ServiceTicket.create!(:granted_by_tgt_id => @ticket_granting_ticket, 
        :service => "www.another.com", :ticket => "ST-1362563155rFE13971A3BCC04C6B5", :client_hostname => "another", :username => "1")
      Cassy.config[:enable_single_sign_out] = true
    end
    
    it "sends a logout notification for all granted service tickets before being destroyed" do
      Cassy::ServiceTicket.any_instance.should_receive(:send_logout_notification)
      @ticket_granting_ticket.destroy_and_logout_all_service_tickets
      expect {
        Cassy::TicketGrantingTicket.find(@ticket_granting_ticket.id)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
    
    context "logging in with a second session and 'no_concurrent_sessions' enabled" do
      
      before do
        Cassy.config[:no_concurrent_sessions] = true
        @ticket_granting_ticket = Cassy::TicketGrantingTicket.create!(:ticket => "TGT-981276451234567890", :username => "1", :client_hostname => "127.0.0.1")
      end
      
      it "returns any ticket_granting_tickets that were created after the one stored in the session" do
        @second_ticket_granting_ticket = Cassy::TicketGrantingTicket.generate("1", nil, "127.0.0.1")
        @ticket_granting_ticket.not_the_latest_for_this_user?.should be_true
      end
      
      it "should send a request to terminate the old session" do
        Cassy::TicketGrantingTicket.any_instance.should_receive(:destroy_and_logout_all_service_tickets)
        @second_ticket_granting_ticket = Cassy::TicketGrantingTicket.generate("1", nil, "127.0.0.1")
      end
      
    end
    
    context "logging in with a second session and 'no_concurrent_sessions' disabled" do
      
      before do
        Cassy::TicketGrantingTicket.delete_all
        Cassy.config[:no_concurrent_sessions] = nil
        @ticket_granting_ticket = Cassy::TicketGrantingTicket.create!(:ticket => "TGT-981276451234567890", :username => "1", :client_hostname => "127.0.0.1")
      end
      
      it "should have two sessions" do
        Cassy::TicketGrantingTicket.any_instance.should_not_receive(:destroy_and_logout_all_service_tickets)
        @second_ticket_granting_ticket = Cassy::TicketGrantingTicket.generate("1", nil, "127.0.0.1")
        Cassy::TicketGrantingTicket.where(:username => "1").count.should == 2
      end
      
    end
    
    it "returns the previous ticket for the username" do
      Cassy.config[:enable_single_sign_out] = true # otherwise they will be deleted
      @second_ticket_granting_ticket = Cassy::TicketGrantingTicket.generate("1", nil, "127.0.0.1")
      @second_ticket_granting_ticket.previous_ticket.should == @ticket_granting_ticket
    end
  
  end
  
end