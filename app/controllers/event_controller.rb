class EventController < ApplicationController

  def create
    logger.info params
    e = Event.new
    e.ip = request.ip.to_s
    e.longitude = params[:lon]
    e.latitude  = params[:lat]
    unless e.save
      logger.warn("Failed to create event with: params=#{params.inspect}, IP=#{request.ip}, err=#{e.errors.inspect}")
    end
    respond_to do |format|
      format.html { redirect_to :root }
      format.json { render json: {}, status: :ok }
    end
  end

  def index
    @events = Event.all
  end

end

