namespace :nlu do
  desc "Show NLU cache statistics"
  task stats: :environment do
    total = NluCache.count
    hits = NluCache.sum(:hit_count)
    recent = NluCache.where("created_at > ?", 7.days.ago).count

    puts "NLU Cache Statistics"
    puts "-" * 40
    puts "Total cached queries: #{total}"
    puts "Total cache hits: #{hits}"
    puts "New entries (7 days): #{recent}"

    if total > 0
      puts "\nTop 10 most-used queries:"
      NluCache.order(hit_count: :desc).limit(10).each_with_index do |cache, i|
        puts "  #{i + 1}. \"#{cache.original_query}\" (#{cache.hit_count} hits)"
      end
    end
  end

  desc "Cleanup stale NLU cache entries (older than 30 days with < 3 hits)"
  task cleanup: :environment do
    deleted = NluCache.cleanup_stale(days: 30)
    puts "Deleted #{deleted} stale cache entries"
  end

  desc "Clear all NLU cache entries"
  task clear: :environment do
    count = NluCache.count
    NluCache.delete_all
    puts "Cleared #{count} cache entries"
  end

  desc "Warm NLU cache with common queries"
  task warm: :environment do
    return unless NluSearchService.enabled?

    common_queries = [
      "postal code for Phnom Penh",
      "postal code for Siem Reap",
      "communes in Phnom Penh",
      "districts in Battambang",
      "what is the code for Kandal",
      "near Angkor Wat",
      "code for BKK1"
    ]

    puts "Warming NLU cache with #{common_queries.size} common queries..."

    common_queries.each do |query|
      cached = NluCache.lookup(query)
      if cached
        puts "  [CACHED] #{query}"
      else
        intent = NluSearchService.parse(query)
        if intent
          puts "  [PARSED] #{query} -> #{intent[:intent]} (#{intent[:confidence]})"
        else
          puts "  [FAILED] #{query}"
        end
      end
      sleep 0.5 # Rate limiting
    end

    puts "Done!"
  end

  desc "Test NLU parsing for a query"
  task :test, [ :query ] => :environment do |_t, args|
    query = args[:query]
    if query.blank?
      puts "Usage: rake nlu:test['your query here']"
      exit 1
    end

    unless NluSearchService.enabled?
      puts "NLU is not enabled. Set anthropic.api_key in credentials."
      exit 1
    end

    puts "Query: \"#{query}\""
    puts "-" * 40

    # Check cache
    cached = NluCache.lookup(query)
    if cached
      puts "Source: CACHED"
      puts "Intent: #{cached.to_json}"
    else
      puts "Source: API"
      intent = NluSearchService.parse(query)
      if intent
        puts "Intent: #{intent.to_json}"

        # Execute the intent
        result = NluQueryExecutor.execute(intent)
        puts "\nResults: #{result[:results].size} matches"
        puts "Context: #{result[:context]}"

        if result[:results].any?
          puts "\nTop 5 results:"
          result[:results].first(5).each do |pc|
            puts "  #{pc.postal_code} - #{pc.name_en} (#{pc.location_type})"
          end
        end
      else
        puts "Failed to parse query"
      end
    end
  end
end
