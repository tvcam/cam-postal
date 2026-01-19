namespace :learned_aliases do
  desc "Show statistics about learned aliases"
  task stats: :environment do
    total = LearnedAlias.count
    promoted = LearnedAlias.promoted.count
    pending = LearnedAlias.pending.count

    puts "Learned Aliases Statistics"
    puts "-" * 30
    puts "Total records:     #{total}"
    puts "Promoted aliases:  #{promoted}"
    puts "Pending:           #{pending}"

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
