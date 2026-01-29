module ProvinceVibes
  extend ActiveSupport::Concern

  PROVINCE_DATA = {
    "01" => {
      name: "Banteay Meanchey",
      emoji: "🏛️",
      taglines: [ "Border town adventures", "Gateway to Thailand" ],
      categories: [ :adventure ]
    },
    "02" => {
      name: "Battambang",
      emoji: "🎨",
      taglines: [ "Art, architecture & bamboo trains", "Cambodia's rice bowl" ],
      categories: [ :culture, :foodie ]
    },
    "03" => {
      name: "Kampong Cham",
      emoji: "🌉",
      taglines: [ "Mekong River vibes", "Bamboo bridge crossing" ],
      categories: [ :culture ]
    },
    "04" => {
      name: "Kampong Chhnang",
      emoji: "🏺",
      taglines: [ "Pottery villages & floating life", "Hidden gem by the river" ],
      categories: [ :culture, :adventure ]
    },
    "05" => {
      name: "Kampong Speu",
      emoji: "🍇",
      taglines: [ "Pepper farms & waterfalls", "Nature escape from the city" ],
      categories: [ :adventure ]
    },
    "06" => {
      name: "Kampong Thom",
      emoji: "🛕",
      taglines: [ "Pre-Angkorian temples await", "Sambor Prei Kuk mysteries" ],
      categories: [ :temple, :culture ]
    },
    "07" => {
      name: "Kampot",
      emoji: "🌶️",
      taglines: [ "Pepper fields & riverside chill", "Sunset at Bokor Mountain" ],
      categories: [ :foodie, :beach, :adventure ]
    },
    "08" => {
      name: "Kandal",
      emoji: "🚤",
      taglines: [ "Mekong islands & silk villages", "Day trip from Phnom Penh" ],
      categories: [ :culture ]
    },
    "09" => {
      name: "Koh Kong",
      emoji: "🌴",
      taglines: [ "Jungle waterfalls & wild coast", "Cambodia's last frontier" ],
      categories: [ :beach, :adventure ]
    },
    "10" => {
      name: "Kratie",
      emoji: "🐬",
      taglines: [ "Spot the Irrawaddy dolphins!", "Mekong magic" ],
      categories: [ :adventure, :culture ]
    },
    "11" => {
      name: "Mondul Kiri",
      emoji: "🐘",
      taglines: [ "Wild elephants & waterfalls", "Highland adventure awaits" ],
      categories: [ :adventure ]
    },
    "12" => {
      name: "Phnom Penh",
      emoji: "🏙️",
      taglines: [ "Moto traffic & rooftop bars", "The city never sleeps" ],
      categories: [ :city, :foodie, :culture ]
    },
    "13" => {
      name: "Preah Vihear",
      emoji: "⛰️",
      taglines: [ "Cliff-top temple views", "Sacred mountain sanctuary" ],
      categories: [ :temple, :adventure ]
    },
    "14" => {
      name: "Prey Veng",
      emoji: "🌾",
      taglines: [ "Authentic rural Cambodia", "Rice paddies forever" ],
      categories: [ :culture ]
    },
    "15" => {
      name: "Pursat",
      emoji: "💎",
      taglines: [ "Floating villages & gems", "Tonle Sap treasures" ],
      categories: [ :adventure, :culture ]
    },
    "16" => {
      name: "Ratanak Kiri",
      emoji: "🌋",
      taglines: [ "Volcanic lakes & hill tribes", "Red earth adventures" ],
      categories: [ :adventure ]
    },
    "17" => {
      name: "Siem Reap",
      emoji: "🛕",
      taglines: [ "Ancient temples await", "Sunrise at Angkor Wat" ],
      categories: [ :temple, :culture, :foodie ]
    },
    "18" => {
      name: "Preah Sihanouk",
      emoji: "🏖️",
      taglines: [ "Beach vibes only", "Island hopping paradise" ],
      categories: [ :beach ]
    },
    "19" => {
      name: "Stung Treng",
      emoji: "🚣",
      taglines: [ "Mekong kayaking adventures", "Where rivers meet" ],
      categories: [ :adventure ]
    },
    "20" => {
      name: "Svay Rieng",
      emoji: "🚏",
      taglines: [ "Border crossing vibes", "Gateway adventures" ],
      categories: [ :culture ]
    },
    "21" => {
      name: "Takeo",
      emoji: "🏛️",
      taglines: [ "Ancient Angkor Borei ruins", "Birthplace of Khmer empire" ],
      categories: [ :temple, :culture ]
    },
    "22" => {
      name: "Oddar Meanchey",
      emoji: "🌳",
      taglines: [ "Remote temple discoveries", "Off the beaten path" ],
      categories: [ :temple, :adventure ]
    },
    "23" => {
      name: "Kep",
      emoji: "🦀",
      taglines: [ "Fresh crab & sunset views", "Old-world beach charm" ],
      categories: [ :beach, :foodie ]
    },
    "24" => {
      name: "Pailin",
      emoji: "💎",
      taglines: [ "Gem mining frontier", "Mountain border town" ],
      categories: [ :adventure ]
    },
    "25" => {
      name: "Tboung Khmum",
      emoji: "🌿",
      taglines: [ "Rubber plantations & rivers", "Peaceful countryside" ],
      categories: [ :culture, :adventure ]
    }
  }.freeze

  CATEGORIES = {
    any: { emoji: "🎲", label: "Anywhere", query: nil },
    beach: { emoji: "🏖️", label: "Beach", query: "Cambodia beach" },
    adventure: { emoji: "⛰️", label: "Adventure", query: "Cambodia adventure" },
    foodie: { emoji: "🍜", label: "Foodie", query: "Cambodia food" },
    city: { emoji: "🏙️", label: "City", query: "Cambodia city" },
    temple: { emoji: "🛕", label: "Temples", query: "Cambodia temple" },
    culture: { emoji: "🎭", label: "Culture", query: "Cambodia culture" }
  }.freeze

  class_methods do
    def random_destination(category: nil)
      provinces = if category.present? && category.to_sym != :any
        PROVINCE_DATA.select { |_, data| data[:categories].include?(category.to_sym) }.keys
      else
        PROVINCE_DATA.keys
      end

      return nil if provinces.empty?

      province_code = provinces.sample
      # Get a random commune from this province for more specific result
      postal_code = where("postal_code LIKE ?", "#{province_code}%")
                    .where(location_type: "commune")
                    .order("RANDOM()")
                    .first

      # Fallback to province or district if no commune
      postal_code ||= where("postal_code LIKE ?", "#{province_code}%")
                      .order("RANDOM()")
                      .first

      postal_code
    end

    def province_vibe(province_code)
      code = province_code.to_s[0, 2]
      PROVINCE_DATA[code] || { name: "Cambodia", emoji: "🇰🇭", taglines: [ "Adventure awaits" ], categories: [ :adventure ] }
    end

    def categories_for_filter
      CATEGORIES
    end
  end

  def vibe
    self.class.province_vibe(postal_code)
  end

  def random_tagline
    vibe[:taglines].sample
  end

  def province_emoji
    vibe[:emoji]
  end

  def share_text
    <<~TEXT.strip
      🎲 Cambodia Postal Code chose my next trip!

      #{province_emoji} #{vibe[:name].upcase} #{province_emoji}
      "#{random_tagline}"

      Let fate decide YOUR adventure 👇
      cambo-postal.com/surprise

      #CambodiaTravel #WhereToGo #RandomAdventure
    TEXT
  end

  def youtube_search_url(locale: I18n.locale)
    query = build_search_query(locale, "travel")
    "https://www.youtube.com/results?search_query=#{CGI.escape(query)}"
  end

  def tiktok_search_url(locale: I18n.locale)
    query = build_search_query(locale)
    "https://www.tiktok.com/search?q=#{CGI.escape(query)}"
  end

  private

  def build_search_query(locale, suffix = nil)
    province_name = vibe[:name]
    case locale.to_sym
    when :km
      # Khmer: use Khmer name if available, plus ប្រទេសកម្ពុជា (Cambodia)
      khmer_name = name_km.presence || province_name
      base = "#{khmer_name} កម្ពុជា"
      suffix ? "#{base} ទេសចរណ៍" : base  # ទេសចរណ៍ = tourism/travel
    when :fr
      base = "#{province_name} Cambodge"
      suffix ? "#{base} voyage" : base
    else
      base = "#{province_name} Cambodia"
      suffix ? "#{base} #{suffix}" : base
    end
  end
end
