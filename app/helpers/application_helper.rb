module ApplicationHelper
  def highlight_match(text, query)
    return text if query.blank? || text.blank?

    terms = query.to_s.downcase.split
    result = text.dup

    terms.each do |term|
      # Match the term and similar variations
      pattern = build_highlight_pattern(term)
      result = result.gsub(pattern) do |match|
        "<mark>#{match}</mark>"
      end
    end

    result.html_safe
  end

  private

  def build_highlight_pattern(term)
    # Build regex that matches the term and common variations
    escaped = Regexp.escape(term)
    # Handle ou/uo swap
    if term.include?("ou")
      alt = term.gsub("ou", "uo")
      escaped = "(?:#{escaped}|#{Regexp.escape(alt)})"
    elsif term.include?("uo")
      alt = term.gsub("uo", "ou")
      escaped = "(?:#{escaped}|#{Regexp.escape(alt)})"
    end

    Regexp.new(escaped, Regexp::IGNORECASE)
  end
end
