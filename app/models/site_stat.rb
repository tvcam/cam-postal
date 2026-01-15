class SiteStat < ApplicationRecord
  validates :name, presence: true, uniqueness: true

  def self.increment(name)
    stat = find_or_create_by(name: name) { |s| s.value = 0 }
    stat.increment!(:value)
  end

  def self.get(name)
    find_by(name: name)&.value || 0
  end

  def self.searches
    get("searches")
  end

  def self.copies
    get("copies")
  end

  def self.visits
    get("visits")
  end
end
