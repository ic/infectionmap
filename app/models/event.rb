class Event < ActiveRecord::Base

  validates :longitude, presence: true
  validates :latitude, presence: true
  validates :ip, presence: true

end

