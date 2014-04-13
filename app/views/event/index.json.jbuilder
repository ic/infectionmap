json.array!(@events) do |e|
  json.extract! e, :ip, :latitude, :longitude, :created_at
end

