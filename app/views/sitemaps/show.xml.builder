xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do
  # Homepage
  xml.url do
    xml.loc root_url(host: @host, protocol: @protocol)
    xml.changefreq "daily"
    xml.priority "1.0"
  end

  # Individual postal code pages
  @postal_codes.each do |postal_code|
    xml.url do
      xml.loc search_url(host: @host, protocol: @protocol, q: postal_code.postal_code)
      xml.changefreq "monthly"
      xml.priority postal_code.province? ? "0.8" : (postal_code.district? ? "0.6" : "0.5")
    end
  end
end
