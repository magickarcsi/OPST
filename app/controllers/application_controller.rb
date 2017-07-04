class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :authenticate_person!

  def hello
    render html: "hello, world!"
  end
end