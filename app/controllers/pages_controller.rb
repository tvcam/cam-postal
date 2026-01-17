class PagesController < ApplicationController
  def privacy
  end

  def terms
  end

  def faq
    SiteStat.increment("visits")
  end
end
