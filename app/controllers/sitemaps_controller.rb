class SitemapsController < ApplicationController
  def show
    @postal_codes = PostalCode.all
    @provinces = PostalCode.provinces.order(:name_en)
    @districts = PostalCode.districts.order(:name_en)
    @host = request.host_with_port
    @protocol = request.protocol
    @lastmod = Date.today.to_s

    respond_to do |format|
      format.xml
    end
  end
end
