class EventController < ApplicationController

  before_action :authenticate_user!, except: [:create, :aggregates]

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

  # PRIVATE, detailed data for the project research.
  # GET /events.json
  def index
    @events = Event.all
    respond_to do |format|
      format.html { render }
      format.json { render json: @events.collect{|e|
        {
          disease: e.event_type,
          type: e.event_subtype,
          lat: e.latitude,
          lon: e.longitude,
          gender: e.gender,
          age: e.age,
          weight: 1
        }
      }, status: :ok }
    end
  end

  # PRIVATE
  def export
    @events = Event.all
    respond_to do |format|
      format.csv { render_csv "events-#{Time.now}" }
      format.json { render json: @events.collect{|e|
        {
          disease: e.event_type,
          type: e.event_subtype,
          lat: e.latitude,
          lon: e.longitude,
          gender: e.gender,
          age: e.age,
          weight: 1
        }
      }, status: :ok, template: :index }
    end
  end

  # PUBLIC, aggregated data for privacy protection.
  # GET /events.json
  def aggregates
    @events = Aggregate.all
    respond_to do |format|
      format.json { render json: @events.collect{|e|
        {
          disease: e.disease,
          lat: e.latitude,
          lon: e.longitude,
          weight: e.weight,
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

  def render_csv(filename = nil)
    filename ||= 'data'
    filename += '.csv'

    if request.env['HTTP_USER_AGENT'] =~ /msie/i
      headers['Pragma'] = 'public'
      headers["Content-type"] = "text/plain"
      headers['Cache-Control'] = 'no-cache, must-revalidate, post-check=0, pre-check=0'
      headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
      headers['Expires'] = "0"
    else
      headers["Content-Type"] ||= 'text/csv'
      headers["Content-Disposition"] = "attachment; filename=\"#{filename}\""
    end

    render layout: false
  end

end

