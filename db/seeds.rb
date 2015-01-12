# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

[
  ['eric.platon@gmail.com', 'changeme'],
  ['wataru.ohira.1@facebook.com', 'changeme'],
].each do |email, pass|
  User.find_or_create_by!(email: email) do |user|
    user.password = user.password_confirmation = pass
    user.confirm!
  end
end

