class CapsuleHeart < ApplicationRecord
  belongs_to :time_capsule, counter_cache: :hearts_count

  validates :ip_hash, presence: true, uniqueness: { scope: :time_capsule_id }
end
