class LocationsController < ApplicationController
  def provinces
    @provinces = PostalCode.provinces.order(:name_en)
    track_visit
  end

  def province
    @province = find_province_by_slug(params[:province])

    unless @province
      render file: Rails.root.join("public/404.html"), status: :not_found, layout: false
      return
    end

    @districts = PostalCode.districts
                           .where("postal_code LIKE ?", "#{@province.postal_code[0, 2]}%")
                           .order(:name_en)
    track_visit
  end

  def district
    @province = find_province_by_slug(params[:province])
    @district = find_district_by_slug(params[:district], @province)

    unless @province && @district
      render file: Rails.root.join("public/404.html"), status: :not_found, layout: false
      return
    end

    @communes = PostalCode.communes
                          .where("postal_code LIKE ?", "#{@district.postal_code[0, 4]}%")
                          .order(:name_en)
    track_visit
  end

  private

  def find_province_by_slug(slug)
    PostalCode.provinces.find { |p| p.name_en.parameterize == slug }
  end

  def find_district_by_slug(slug, province)
    return nil unless province

    PostalCode.districts
              .where("postal_code LIKE ?", "#{province.postal_code[0, 2]}%")
              .find { |d| d.name_en.parameterize == slug }
  end
end
