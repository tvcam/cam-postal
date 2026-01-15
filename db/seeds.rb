# Cambodia Postal Codes Seed Data
# Source: Ministry of Post and Telecommunications

require 'csv'

puts "Loading postal codes..."

csv_path = Rails.root.join('db', 'postal_codes.csv')
data = CSV.read(csv_path, headers: true)

data.each do |row|
  pc = PostalCode.find_or_initialize_by(postal_code: row['postal_code'])
  pc.name_km = row['name_km']
  pc.name_en = row['name_en']
  pc.location_type = row['type']
  pc.save!
end

puts "Loaded #{PostalCode.count} postal codes."
