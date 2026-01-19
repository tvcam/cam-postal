class PostalCodesController < ApplicationController
  def data
    expires_in 1.week, public: true
    log_api_access("/data.json")

    # Only include valid 6-digit postal codes
    postal_codes = PostalCode.where("LENGTH(postal_code) = 6").order(:postal_code)

    # Build lookups for parent names
    provinces = postal_codes.select(&:province?).index_by(&:postal_code)
    districts = postal_codes.select(&:district?).index_by(&:postal_code)

    data = postal_codes.map do |pc|
      parent = case pc.location_type
      when "commune"
        district = districts[pc.district_code]
        province = provinces[pc.province_code]
        [ district&.name_en, province&.name_en ].compact.join(", ")
      when "district"
        provinces[pc.province_code]&.name_en || ""
      else
        ""
      end

      { code: pc.postal_code, name_en: pc.name_en, name_km: pc.name_km, type: pc.location_type, parent: parent }
    end

    # Include aliases for client-side search
    render json: { data: data, aliases: PostalCode.aliases }
  end

  def index
    @query = params[:q].to_s.strip
    @results = @query.present? ? PostalCode.search(@query) : []
    track_visit
  end

  def show
    @postal_code = PostalCode.find_by!(postal_code: params[:postal_code])
    track_visit

    # Get related postal codes for internal linking
    @related_codes = if @postal_code.commune?
      PostalCode.communes.where("postal_code LIKE ?", "#{@postal_code.postal_code[0, 4]}%")
                .where.not(id: @postal_code.id)
                .order(:name_en)
                .limit(6)
    elsif @postal_code.district?
      PostalCode.districts.where("postal_code LIKE ?", "#{@postal_code.postal_code[0, 2]}%")
                .where.not(id: @postal_code.id)
                .order(:name_en)
                .limit(6)
    else
      PostalCode.provinces.where.not(id: @postal_code.id).order(:name_en).limit(6)
    end
  end

  def search
    @query = params[:q].to_s.strip
    limit = params[:limit].to_i
    limit = nil if limit <= 0 || limit > 50

    @nlu_used = false
    @nlu_context = nil
    @error = nil

    if @query.present?
      # Try NLU for natural language queries
      if should_use_nlu?(@query)
        nlu_result = perform_nlu_search(@query)
        if nlu_result
          @results = nlu_result[:results]
          @nlu_context = nlu_result[:context]
          @nlu_used = true
        end
      end

      # Fall back to regular search if NLU didn't produce results
      @results ||= PostalCode.search(@query, limit: limit)
    else
      @results = []
    end

    track_search if @query.present?

    respond_to do |format|
      format.html do
        if turbo_frame_request?
          render layout: false
        else
          render :search_page
        end
      end
      format.turbo_stream
    end
  rescue StandardError => e
    Rails.logger.error "Search error: #{e.class} - #{e.message}"
    @error = I18n.t("errors.search_error.message")
    @results = []

    respond_to do |format|
      format.html do
        if turbo_frame_request?
          render layout: false
        else
          render :search_page
        end
      end
      format.turbo_stream { render turbo_stream: turbo_stream.replace("search-results", partial: "postal_codes/search_error") }
      format.json { render json: { error: @error }, status: :service_unavailable }
    end
  end

  def record_copy
    track_copy

    # Track for learned aliases
    query = params[:q].to_s.strip
    postal_code = params[:code].to_s.strip
    if query.present? && postal_code.present? && !bot_request?
      LearnedAlias.record_click(query, postal_code, ip_address: request.remote_ip)
    end

    head :ok
  end

  def record_search
    query = params[:q].to_s.strip
    if query.present? && !bot_request?
      track_search
      log_search_query(query)
      LearnedAlias.record_search(query, ip_address: request.remote_ip)
    end
    head :ok
  end

  def locate
    lat = params[:lat].to_f
    lng = params[:lng].to_f

    return render json: { error: "Invalid coordinates" }, status: :bad_request if lat.zero? || lng.zero?

    result = GeocodeCache.lookup(lat, lng)
    render json: result
  rescue StandardError => e
    Rails.logger.error "Locate error: #{e.class} - #{e.message}"
    render json: { error: "Service temporarily unavailable" }, status: :service_unavailable
  end

  # private

  def log_search_query(query, results_count: 0)
    SearchLog.log_search(
      query: query,
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      results_count: results_count
    )
  rescue StandardError => e
    Rails.logger.error "Failed to log search: #{e.message}"
  end

  def log_api_access(endpoint)
    ApiAccessLog.log_access(
      endpoint: endpoint,
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      referer: request.referer
    )
  rescue StandardError => e
    Rails.logger.error "Failed to log API access: #{e.message}"
  end

  def llms_full
    expires_in 1.day, public: true

    postal_codes = PostalCode.order(:postal_code)

    # Build lookups for parent names
    provinces = postal_codes.select(&:province?).index_by(&:postal_code)
    districts = postal_codes.select(&:district?).index_by(&:postal_code)

    lines = [ "# Cambodia Postal Codes - Complete Database",
              "# Format: POSTAL_CODE | TYPE | NAME_EN | NAME_KM | PARENT_LOCATION",
              "# Generated: #{Time.current.strftime('%Y-%m-%d')}",
              "# Total records: #{postal_codes.count}",
              "#",
              "# Province codes: 01-25 (first 2 digits)",
              "# District codes: 4 digits (province + district)",
              "# Commune codes: 6 digits (province + district + commune)",
              "",
              "POSTAL_CODE | TYPE | NAME_EN | NAME_KM | PARENT",
              "-" * 80 ]

    postal_codes.each do |pc|
      parent = case pc.location_type
      when "commune"
        district = districts[pc.district_code]
        province = provinces[pc.province_code]
        [ district&.name_en, province&.name_en ].compact.join(", ")
      when "district"
        provinces[pc.province_code]&.name_en || ""
      else
        "Cambodia"
      end

      lines << "#{pc.postal_code} | #{pc.location_type.ljust(8)} | #{pc.name_en} | #{pc.name_km || '-'} | #{parent}"
    end

    render plain: lines.join("\n"), content_type: "text/plain; charset=utf-8"
  end

  private

  # Determine if query should trigger NLU processing
  def should_use_nlu?(query)
    return false unless NluSearchService.enabled?
    return false if query.length < 5
    return false if query.match?(/^\d{2,6}$/) # Pure postal code numbers

    # Trigger NLU for natural language patterns
    nlu_patterns = [
      /\b(what|where|which|how|find|get|show)\b/i,
      /\b(postal\s*code|zip\s*code)\s+(for|of|in)\b/i,
      /\b(communes?|districts?|provinces?)\s+(in|of|for)\b/i,
      /\bnear\b/i,
      /\bcode\s+for\b/i
    ]

    nlu_patterns.any? { |pattern| query.match?(pattern) }
  end

  # Execute NLU search pipeline
  def perform_nlu_search(query)
    intent = NluSearchService.parse(query)
    return nil unless intent
    return nil if intent[:confidence].to_f < 0.7

    result = NluQueryExecutor.execute(intent)
    return nil if result[:results].empty?

    result
  rescue StandardError => e
    Rails.logger.error "[NLU] Error in search: #{e.message}"
    nil
  end
end
