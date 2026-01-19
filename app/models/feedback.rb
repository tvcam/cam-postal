class Feedback < ApplicationRecord
  validates :message, presence: true, length: { minimum: 10, maximum: 2000 }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :name, length: { maximum: 100 }, allow_blank: true

  scope :recent, -> { order(created_at: :desc) }
  scope :unread, -> { where(read_at: nil) }
end
