namespace :postal_codes do
  desc "Fetch missing Khmer names from OpenStreetMap Nominatim"
  task fetch_khmer_names: :environment do
    require "net/http"
    require "json"

    # Only process records without Khmer names
    records = PostalCode.where(name_km: [nil, ""])
    total = records.count
    puts "Found #{total} records missing Khmer names"

    updated = 0
    skipped = 0
    failed = 0

    records.find_each.with_index do |record, index|
      # Rate limit: 1 request per second (Nominatim policy)
      sleep 1 if index > 0

      print "\r[#{index + 1}/#{total}] Processing #{record.name_en}..."

      khmer_name = fetch_khmer_name(record)

      if khmer_name.present?
        # Add prefix based on location type
        prefix = case record.location_type
        when "province" then "ខេត្ត"
        when "district" then "ស្រុក"
        when "commune" then "ឃុំ"
        else ""
        end

        full_name = prefix.present? ? "#{prefix} #{khmer_name}" : khmer_name
        record.update!(name_km: full_name)
        updated += 1
        puts " -> #{full_name}"
      else
        skipped += 1
        puts " -> Not found"
      end
    rescue StandardError => e
      failed += 1
      puts " -> Error: #{e.message}"
    end

    puts "\n\nDone!"
    puts "Updated: #{updated}"
    puts "Not found: #{skipped}"
    puts "Failed: #{failed}"

    # Rebuild FTS index
    if updated > 0
      puts "\nRebuilding FTS index..."
      ActiveRecord::Base.connection.execute("INSERT INTO postal_codes_fts(postal_codes_fts) VALUES('rebuild')")
      puts "FTS index rebuilt."
    end
  end

  def fetch_khmer_name(record)
    # Clean the name for search
    search_name = record.name_en
      .gsub(/\s+(Province|District|Commune|City|Municipality|Town)$/i, "")
      .gsub(/^(Krong|Khan|Sangkat)\s+/i, "")
      .strip

    # Search on Nominatim with Khmer language
    uri = URI("https://nominatim.openstreetmap.org/search")
    params = {
      q: "#{search_name}, Cambodia",
      format: "json",
      namedetails: 1,
      "accept-language" => "km",
      limit: 1
    }
    uri.query = URI.encode_www_form(params)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 10

    request = Net::HTTP::Get.new(uri)
    request["User-Agent"] = "CambodiaPostalCode/1.0 (fetching Khmer names)"

    response = http.request(request)
    return nil unless response.is_a?(Net::HTTPSuccess)

    data = JSON.parse(response.body)
    return nil if data.empty?

    result = data.first
    namedetails = result["namedetails"] || {}

    # Try to get Khmer name from various fields
    khmer_name = namedetails["name:km"] ||
                 namedetails["official_name:km"] ||
                 namedetails["alt_name:km"]

    # If the main name is in Khmer script, use it
    if khmer_name.nil? && result["name"]&.match?(/[\u1780-\u17FF]/)
      khmer_name = result["name"]
    end

    khmer_name
  end
end
