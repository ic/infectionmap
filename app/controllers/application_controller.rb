class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session

  before_action :expose_agent

  def expose_agent
    @agent = request.user_agent
  end

  def self.redis
    @@redis ||= Redis.new
  end

  def redis
    self.redis
  end

end
