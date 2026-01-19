namespace :learned_aliases do
  desc "Cleanup stale learned aliases (not clicked in 2 months)"
  task cleanup: :environment do
    puts "Cleaning up stale learned aliases..."
    result = LearnedAlias.cleanup_stale!
    puts "Deleted #{result[:deleted]} stale records"
    puts "Demoted #{result[:demoted]} stale promoted aliases"
  end

  desc "Show statistics about learned aliases"
  task stats: :environment do
    total = LearnedAlias.count
    promoted = LearnedAlias.promoted.count
    pending = LearnedAlias.pending.count
    stale = LearnedAlias.stale.count

    puts "Learned Aliases Statistics"
    puts "-" * 30
    puts "Total records:     #{total}"
    puts "Promoted aliases:  #{promoted}"
    puts "Pending:           #{pending}"
    puts "Stale (>2 months): #{stale}"

    if promoted > 0
      puts "\nTop 10 Promoted Aliases:"
      LearnedAlias.promoted.order(click_count: :desc).limit(10).each do |la|
        location = PostalCode.find_by(postal_code: la.postal_code)
        puts "  '#{la.search_term}' -> #{la.postal_code} (#{location&.name_en}) [#{la.click_count} clicks]"
      end
    end
  end

  desc "List all promoted aliases"
  task list: :environment do
    aliases = LearnedAlias.promoted.order(:search_term)
    if aliases.empty?
      puts "No promoted aliases yet."
    else
      puts "Promoted Learned Aliases (#{aliases.count} total):"
      puts "-" * 50
      aliases.each do |la|
        location = PostalCode.find_by(postal_code: la.postal_code)
        puts "#{la.search_term.ljust(25)} -> #{la.postal_code} (#{location&.name_en})"
      end
    end
  end
end
