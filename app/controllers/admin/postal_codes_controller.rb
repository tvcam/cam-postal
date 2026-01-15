module Admin
  class PostalCodesController < ApplicationController
    http_basic_authenticate_with name: ENV.fetch("ADMIN_USER", "admin"),
                                 password: ENV.fetch("ADMIN_PASSWORD", "password")

    def index
      @provinces = PostalCode.provinces.order(:name_en).pluck(:name_en)
      @districts = PostalCode.districts.order(:name_en).pluck(:name_en)

      # Default to first province if no filter selected
      params[:province_filter] ||= @provinces.first

      scope = PostalCode.order(:location_type, :name_en)

      scope = filter_by_province(scope) if params[:province_filter].present?
      scope = filter_by_district(scope) if params[:district_filter].present?
      scope = scope.where(location_type: params[:type]) if params[:type].present?

      @postal_codes = scope
      @total_count = @postal_codes.count
    end

    private

    def filter_by_province(scope)
      province_code = PostalCode.provinces.find_by(name_en: params[:province_filter])&.code
      return scope unless province_code

      scope.where("code LIKE ?", "#{province_code}%")
    end

    def filter_by_district(scope)
      district_code = PostalCode.districts.find_by(name_en: params[:district_filter])&.code
      return scope unless district_code

      scope.where("code LIKE ?", "#{district_code}%")
    end
  end
end
