class PostalCodesController < ApplicationController
  def data
    expires_in 1.week, public: true

    postal_codes = PostalCode.order(:postal_code)

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

      { c: pc.postal_code, e: pc.name_en, k: pc.name_km, t: pc.location_type, p: parent }
    end

    render json: data
  end

  def index
    @query = params[:q].to_s.strip
    @results = @query.present? ? PostalCode.search(@query) : []
    SiteStat.increment("visits")
  end

  def show
    @postal_code = PostalCode.find_by!(postal_code: params[:postal_code])
    SiteStat.increment("visits")

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
  rescue ActiveRecord::RecordNotFound
    render file: Rails.root.join("public/404.html"), status: :not_found, layout: false
  end

  def search
    @query = params[:q].to_s.strip
    @results = @query.present? ? PostalCode.search(@query) : []

    SiteStat.increment("searches") if @query.present?

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
  end

  def track_copy
    SiteStat.increment("copies")
    head :ok
  end

  def track_search
    SiteStat.increment("searches")
    head :ok
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
end
