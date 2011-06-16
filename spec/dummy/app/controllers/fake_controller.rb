class FakeController < ApplicationController
  def index
    render :text => "Welcome home."
  end
end