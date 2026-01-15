namespace :postal_codes do
  desc "Sync postal codes from CSV - updates missing Khmer names and adds new records"
  task sync: :environment do
    require "csv"

    csv_path = Rails.root.join("db", "postal_codes.csv")
    unless File.exist?(csv_path)
      puts "Error: #{csv_path} not found"
      exit 1
    end

    data = CSV.read(csv_path, headers: true)
    updated = 0
    created = 0
    skipped = 0

    puts "Syncing #{data.size} postal codes..."

    data.each do |row|
      postal_code = row["postal_code"]
      record = PostalCode.find_by(postal_code: postal_code)

      if record
        # Update only if name_km is missing or empty
        if record.name_km.blank? && row["name_km"].present?
          record.update!(name_km: row["name_km"])
          updated += 1
          puts "Updated: #{postal_code} => #{row['name_km']}"
        else
          skipped += 1
        end
      else
        # Create new record
        PostalCode.create!(
          postal_code: row["postal_code"],
          name_km: row["name_km"],
          name_en: row["name_en"],
          location_type: row["type"],
          province_code: row["province_code"],
          district_code: row["district_code"]
        )
        created += 1
        puts "Created: #{postal_code} - #{row['name_en']}"
      end
    end

    puts
    puts "=" * 50
    puts "SUMMARY"
    puts "=" * 50
    puts "Updated (added Khmer name): #{updated}"
    puts "Created (new records):      #{created}"
    puts "Skipped (already complete): #{skipped}"
    puts "Total in database:          #{PostalCode.count}"
  end

  desc "Import all postal codes from CSV (fresh import)"
  task import: :environment do
    require "csv"

    csv_path = Rails.root.join("db", "postal_codes.csv")
    data = CSV.read(csv_path, headers: true)

    puts "Importing #{data.size} postal codes..."

    PostalCode.transaction do
      data.each do |row|
        PostalCode.find_or_initialize_by(postal_code: row["postal_code"]).tap do |pc|
          pc.name_km = row["name_km"]
          pc.name_en = row["name_en"]
          pc.location_type = row["type"]
          pc.save!
        end
      end
    end

    puts "Imported #{PostalCode.count} postal codes."
  end
end
