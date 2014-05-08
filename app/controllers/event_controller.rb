class EventController < ApplicationController

  def create
    logger.info params
    e = Event.new

    # Required
    e.ip = request.ip.to_s
    e.longitude = params[:lon]
    e.latitude  = params[:lat]
    e.event_type = params[:disease]

    # Optional
    e.gender = params[:gender] unless params[:gender].blank?
    begin
      e.age = params[:age].to_i unless params[:age].blank?
    rescue => ex
      logger.error ex.inspect
      # Ignored
    end
    e.event_subtype = params[:disease_type] unless params[:disease_type].blank?

    unless e.save
      logger.warn("Failed to create event with: params=#{params.inspect}, IP=#{request.ip}, err=#{e.errors.inspect}")
    end
    respond_to do |format|
      format.html { redirect_to redirect_target(e.event_type) }
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

  private
  def redirect_target(event)
    case event
    when 'influenza' then :influenza
    when 'dengue' then :denguefever
    else :root
    end
  end

end

