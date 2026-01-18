import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button"]

  connect() {
    // Only show if Web Share API is supported
    if (navigator.share && this.hasButtonTarget) {
      this.buttonTarget.style.display = "inline-flex"
    }
  }

  async share() {
    if (!navigator.share) return

    try {
      await navigator.share({
        title: "Cambodia Postal Code Directory",
        text: "Search postal codes for all Cambodia provinces, districts and communes",
        url: window.location.href
      })
    } catch {
      // User cancelled or share failed - no action needed
    }
  }
}
