class PagesController < ApplicationController
  def privacy
  end

  def terms
  end

  def faq
    track_visit
  end
end
