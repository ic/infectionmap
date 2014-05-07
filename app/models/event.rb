class Event < ActiveRecord::Base

  validates :longitude, presence: true
  validates :latitude, presence: true
  validates :ip, presence: true

  validates :gender, inclusion: { in: ['male', 'female', nil] }
  #validates :age, numericality: { only_integer: true, greater_than: 0 }

end

