require "net/http"

class TelegramNotifierService
  class << self
    def bot_token
      Rails.application.credentials.dig(:telegram, :bot_token)
    end

    def chat_id
      Rails.application.credentials.dig(:telegram, :chat_id)
    end
  end

  def self.send_message(message, parse_mode: "HTML")
    new.send_message(message, parse_mode: parse_mode)
  end

  def send_message(message, parse_mode: "HTML")
    return false unless self.class.bot_token && self.class.chat_id

    uri = URI("https://api.telegram.org/bot#{self.class.bot_token}/sendMessage")

    params = {
      chat_id: self.class.chat_id,
      text: message,
      parse_mode: parse_mode
    }

    begin
      response = Net::HTTP.post_form(uri, params)

      if response.is_a?(Net::HTTPSuccess)
        Rails.logger.info("Telegram notification sent successfully")
        true
      else
        Rails.logger.error("Failed to send Telegram notification: #{response.code} - #{response.body}")
        false
      end
    rescue => e
      Rails.logger.error("Error sending Telegram notification: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      false
    end
  end

  def self.notify_new_feedback(feedback)
    message = <<~MESSAGE
      📬 <b>New Feedback Received!</b>

      <b>Name:</b> #{feedback.name.presence || "Anonymous"}
      <b>Email:</b> #{feedback.email.presence || "Not provided"}

      <b>Message:</b>
      #{feedback.message}

      <b>Submitted at:</b> #{feedback.created_at.strftime("%Y-%m-%d %H:%M:%S")}
      <b>IP:</b> #{feedback.ip_address}
    MESSAGE

    send_message(message)
  end
end
