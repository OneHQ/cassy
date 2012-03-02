class FakeController < ApplicationController
  def index
    render :text => "Welcome home."
  end
  
  def another_page
    render :text => "Hey you made it to the page of extra content"
  end
end