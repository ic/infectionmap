class EventController < ApplicationController

  def create
    logger.info params
    e = Event.new
    e.ip = request.ip.to_s
    e.longitude = params[:lon]
    e.latitude  = params[:lat]
    e.event_type = params[:disease]
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
    respond_to do |format|
      format.html { render }
      format.json { render json: @events.collect{|e|
        {
          disease: e.event_type,
          lat: e.latitude,
          lon: e.longitude,
          weight: 1
        }
      }, status: :ok }
    end
  end

end

