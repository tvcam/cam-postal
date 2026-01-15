class SitemapsController < ApplicationController
  def show
    @postal_codes = PostalCode.all
    @host = request.host_with_port
    @protocol = request.protocol

    respond_to do |format|
      format.xml
    end
  end
end
