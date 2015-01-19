require 'sidekiq'
require 'sidetiq'

module UpdateAggregatesGears
  APP_ENV = ENV['APP_ENV'] || ENV['RACK_ENV'] || 'development'

  TIME_WINDOW = 15 # days
  CUT_OFF = 500 # m
  EARTH_MAX_RADIUS = 6_378_137 # m
  EARTH_MIN_RADIUS = 6_356_752 # m

  def in_range(p, q)
    test = longitude_delta(p, q) < CUT_OFF && latitude_delta(p, q) < CUT_OFF
    test
  end

  def longitude_delta(p, q)
    lat = [p.lat, q.lat].min
    dLon = (p.lon - q.lon).abs
    if dLon != 0 && dLon != 180
      Math::PI / 180 * EARTH_MAX_RADIUS ** 2 / EARTH_MIN_RADIUS * Math.sin(lat) / Math.tan(dLon)
    else
      Math::PI / 180 * EARTH_MAX_RADIUS * Math.cos(dLon)
    end
  end

  def latitude_delta(p, q)
    dLan = (p.lat - q.lat).abs
    111132.954 - 559.822 * Math.cos(2 * dLan) + 1.175 * Math.cos(4 * dLan)
  end

  class Point
    attr_reader :lat, :lon
    def initialize(latitude, longitude)
      @lat = latitude
      @lon = longitude
    end
    def to_s
      "(#{lat}, #{lon})"
    end
  end
end

case ENV['RACK_ENV']
when 'production' then
  require 'mysql2'
  module UpdateAggregatesGears
    def perform
      logger.info{"Updating aggregates..."}
      two_weeks_ago = Time.now - TIME_WINDOW * 86400

      events = db.query("SELECT * FROM events WHERE created_at >= '#{two_weeks_ago}'")
      aggregates = db.query("SELECT * FROM aggregates WHERE created_at >= '#{two_weeks_ago}' or updated_at >= '#{two_weeks_ago}'")

      db.query("BEGIN TRANSACTION")
      (events || []).each do |event|
        eve = Point.new(event['latitude'], event['longitude'])
        to_update = aggregates.filter{|a|
          agg = Point.new(a['latitude'], a['longitude'])
          in_range(agg, eve) && event['event_type'] == a['disease']
        }.first # Arbitrary: We just update one of the aggregates to receive the new event.
        if to_update
          current_weight = to_udpate['weight'].to_i
          db.query("UPDATE aggregates SET weight = #{current_weight + 1} WHERE id = #{to_udpate['id']}")
        else
          db.execute("INSERT INTO aggregates (disease, latitude, longitude, weight, created_at, updated_at) VALUES ('#{event['event_type']}', '#{event['latitude']}', '#{event['longitude']}', 1, '#{now}', '#{now}')")
        end
      end
      db.query("COMMIT TRANSACTION")

      logger.info{"Updated #{db.affected_rows} aggregates."}
    end

    private
    def db
      @db ||= Mysql2::Client.new(YAML.load_file(File.expand_path(File.join('..', '..', 'config', 'database.yml'), File.dirname(__FILE__)))[APP_ENV])
    end
  end
else
  require 'sqlite3'
  module UpdateAggregatesGears
    def perform
      logger.info{"Updating aggregates..."}
      now = Time.now
      two_weeks_ago = now - TIME_WINDOW * 86400

      events = db.execute("SELECT * FROM events WHERE created_at >= '#{two_weeks_ago}'")
      aggregates = db.execute("SELECT * FROM aggregates WHERE created_at >= '#{two_weeks_ago}' or updated_at >= '#{two_weeks_ago}'")

      (events || []).each do |event|
        eve = Point.new(event['latitude'], event['longitude'])
        to_update = aggregates.select { |a|
          agg = Point.new(a['latitude'], a['longitude'])
          STDOUT << "#{eve} <=> #{agg}"
          in_range(agg, eve) && event['event_type'] == a['disease']
        }.first # Arbitrary: We just update one of the aggregates to receive the new event.
        if to_update
          current_weight = to_udpate['weight'].to_i
          db.execute("UPDATE aggregates SET weight = #{current_weight + 1}, updated_at = #{now} WHERE id = #{to_udpate['id']}")
        else
          db.execute("INSERT INTO aggregates (disease, latitude, longitude, weight, created_at, updated_at) VALUES ('#{event['event_type']}', '#{event['latitude']}', '#{event['longitude']}', 1, '#{now}', '#{now}')")
        end
      end

      logger.info{"Updated aggregates."}
    end

    private
    def db
      return @db if defined?(@db) && !@db.nil?
      @db = SQLite3::Database.new(YAML.load_file(File.expand_path(File.join('..', '..', 'config', 'database.yml'), File.dirname(__FILE__)))[APP_ENV]['database'])
      @db.results_as_hash = true
      @db.type_translation = true
      @db
    end
  end
end

class UpdateAggregates
  include Sidekiq::Worker
  include Sidetiq::Schedulable
  #
  # TODO dedicated queue, otherwise schedule is not "guaranteed".
  #
  sidekiq_options queue: 'default', retry: false, backtrace: true

  # Weird syntax, but recommended to avoid the expensive #minutely.
  recurrence { hourly.minute_of_hour(0, 10, 20, 30, 40, 50) }

  include UpdateAggregatesGears
end

