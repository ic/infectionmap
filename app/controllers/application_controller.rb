class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session

  before_action :expose_agent
  before_action :set_locale

  def expose_agent
    @agent = request.user_agent
  end

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  def self.redis
    @@redis ||= Redis.new
  end

  def redis
    self.redis
  end

  def default_url_options(opt = {})
    logger.debug "default_url_options ignores: #{opt.inspect}"
    { locale: I18n.locale }
  end

end
