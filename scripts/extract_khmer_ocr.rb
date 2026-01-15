#!/usr/bin/env ruby
# Script to extract Khmer postal code data from PDF images using Claude API
# Usage: ANTHROPIC_API_KEY=your_key ruby scripts/extract_khmer_ocr.rb [start_page] [end_page]

require "net/http"
require "json"
require "base64"
require "fileutils"

API_KEY = ENV["ANTHROPIC_API_KEY"]
unless API_KEY
  puts "Error: ANTHROPIC_API_KEY environment variable not set"
  exit 1
end

IMAGE_DIR = File.expand_path("../db/pdf_images", __dir__)
OUTPUT_DIR = File.expand_path("../db/csv_chunks", __dir__)
FileUtils.mkdir_p(OUTPUT_DIR)

def extract_page(page_num)
  image_path = File.join(IMAGE_DIR, "page-%02d.png" % page_num)
  output_path = File.join(OUTPUT_DIR, "page_%02d.csv" % page_num)

  unless File.exist?(image_path)
    puts "Image not found: #{image_path}"
    return false
  end

  if File.exist?(output_path) && File.size(output_path) > 100
    puts "Page #{page_num}: Already extracted, skipping"
    return true
  end

  puts "Page #{page_num}: Extracting..."

  # Read and encode image
  image_data = Base64.strict_encode64(File.read(image_path))

  # Call Claude API
  uri = URI("https://api.anthropic.com/v1/messages")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.read_timeout = 120

  request = Net::HTTP::Post.new(uri)
  request["Content-Type"] = "application/json"
  request["x-api-key"] = API_KEY
  request["anthropic-version"] = "2023-06-01"

  prompt = <<~PROMPT
    Extract the postal code table from this image into CSV format.

    The table has these columns:
    - postal_code (6-digit number in the rightmost column)
    - name_km (Khmer name in the second column)
    - name_en (English name in the third column)
    - type (province/district/commune based on the hierarchy number)

    Rules:
    - Rows starting with single number (1, 2, 3...) are provinces
    - Rows like 1.1, 2.1 are districts
    - Rows like 1.1.1, 2.1.1 are communes
    - Include the Khmer prefix (ខេត្ត/ក្រុង for province, ស្រុក/ខណ្ឌ for district, ឃុំ/សង្កorg for commune)
    - Skip header rows and page numbers

    Output ONLY the CSV data with header: postal_code,name_km,name_en,type,province_code,district_code
    No explanation, just CSV.
  PROMPT

  body = {
    model: "claude-sonnet-4-20250514",
    max_tokens: 4096,
    messages: [
      {
        role: "user",
        content: [
          {
            type: "image",
            source: {
              type: "base64",
              media_type: "image/png",
              data: image_data
            }
          },
          {
            type: "text",
            text: prompt
          }
        ]
      }
    ]
  }

  request.body = JSON.generate(body)
  response = http.request(request)

  if response.code != "200"
    puts "API Error: #{response.code} - #{response.body}"
    return false
  end

  result = JSON.parse(response.body)
  csv_content = result.dig("content", 0, "text")

  # Clean up the response (remove markdown code blocks if present)
  csv_content = csv_content.gsub(/```csv\n?/, "").gsub(/```\n?/, "").strip

  File.write(output_path, csv_content + "\n")
  puts "Page #{page_num}: Saved to #{output_path}"
  true
rescue StandardError => e
  puts "Page #{page_num}: Error - #{e.message}"
  false
end

CHUNK_SIZE = 5  # Process 5 pages then pause
CHUNK_PAUSE = 10  # Seconds to pause between chunks
MAX_RETRIES = 3

def extract_with_retry(page_num)
  retries = 0
  begin
    extract_page(page_num)
  rescue StandardError => e
    retries += 1
    if retries <= MAX_RETRIES
      puts "  Retry #{retries}/#{MAX_RETRIES} after error: #{e.message}"
      sleep 5 * retries
      retry
    else
      puts "  Failed after #{MAX_RETRIES} retries"
      false
    end
  end
end

# Main
start_page = (ARGV[0] || 8).to_i
end_page = (ARGV[1] || 59).to_i

puts "Extracting pages #{start_page} to #{end_page}..."
puts "Output directory: #{OUTPUT_DIR}"
puts "Chunk size: #{CHUNK_SIZE}, pause between chunks: #{CHUNK_PAUSE}s"
puts ""

success = 0
failed = 0
pages = (start_page..end_page).to_a

pages.each_slice(CHUNK_SIZE).with_index do |chunk, chunk_idx|
  puts "=== Chunk #{chunk_idx + 1} (pages #{chunk.first}-#{chunk.last}) ==="

  chunk.each do |page|
    if extract_with_retry(page)
      success += 1
    else
      failed += 1
    end
    sleep 2 # Rate limiting between pages
  end

  # Pause between chunks (unless last chunk)
  if chunk != pages.each_slice(CHUNK_SIZE).to_a.last
    puts "Pausing #{CHUNK_PAUSE}s before next chunk..."
    sleep CHUNK_PAUSE
  end
end

puts ""
puts "=" * 40
puts "Done! Success: #{success}, Failed: #{failed}"
