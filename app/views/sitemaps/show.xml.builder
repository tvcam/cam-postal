xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do
  # Homepage
  xml.url do
    xml.loc root_url(host: @host, protocol: @protocol)
    xml.lastmod @lastmod
    xml.changefreq "daily"
    xml.priority "1.0"
  end

  # Provinces listing page
  xml.url do
    xml.loc provinces_url(host: @host, protocol: @protocol)
    xml.lastmod @lastmod
    xml.changefreq "weekly"
    xml.priority "0.9"
  end

  # FAQ page
  xml.url do
    xml.loc faq_url(host: @host, protocol: @protocol)
    xml.lastmod @lastmod
    xml.changefreq "monthly"
    xml.priority "0.8"
  end

  # Stats page
  xml.url do
    xml.loc stats_url(host: @host, protocol: @protocol)
    xml.lastmod @lastmod
    xml.changefreq "daily"
    xml.priority "0.7"
  end

  # Open Data / API page
  xml.url do
    xml.loc api_url(host: @host, protocol: @protocol)
    xml.lastmod @lastmod
    xml.changefreq "monthly"
    xml.priority "0.7"
  end

  # Privacy page
  xml.url do
    xml.loc privacy_url(host: @host, protocol: @protocol)
    xml.lastmod @lastmod
    xml.changefreq "yearly"
    xml.priority "0.3"
  end

  # Terms page
  xml.url do
    xml.loc terms_url(host: @host, protocol: @protocol)
    xml.lastmod @lastmod
    xml.changefreq "yearly"
    xml.priority "0.3"
  end

  # Feedback page
  xml.url do
    xml.loc new_feedback_url(host: @host, protocol: @protocol)
    xml.lastmod @lastmod
    xml.changefreq "yearly"
    xml.priority "0.5"
  end

  # Individual province pages
  @provinces.each do |province|
    xml.url do
      xml.loc province_url(province.name_en.parameterize, host: @host, protocol: @protocol)
      xml.lastmod @lastmod
      xml.changefreq "weekly"
      xml.priority "0.8"
    end
  end

  # Individual district pages
  @districts.each do |district|
    province = district.province
    next unless province

    xml.url do
      xml.loc province_district_url(province.name_en.parameterize, district.name_en.parameterize, host: @host, protocol: @protocol)
      xml.lastmod @lastmod
      xml.changefreq "monthly"
      xml.priority "0.7"
    end
  end

  # Individual postal code pages
  @postal_codes.each do |pc|
    xml.url do
      xml.loc postal_code_url(pc.postal_code, host: @host, protocol: @protocol)
      xml.lastmod @lastmod
      xml.changefreq "monthly"
      xml.priority pc.province? ? "0.6" : (pc.district? ? "0.5" : "0.4")
    end
  end
end
