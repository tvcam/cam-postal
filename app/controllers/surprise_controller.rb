class SurpriseController < ApplicationController
  def index
    @categories = PostalCode.categories_for_filter
  end

  def reveal
    category = params[:category]&.to_sym
    @destination = PostalCode.random_destination(category: category)

    if @destination.nil?
      redirect_to surprise_path, alert: t("surprise.no_results")
      return
    end

    @vibe = @destination.vibe
    @tagline = @destination.random_tagline
    @share_text = @destination.share_text
    @youtube_url = @destination.youtube_search_url
    @tiktok_url = @destination.tiktok_search_url

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end
end
