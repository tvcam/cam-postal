import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button"]
  static values = { text: String }

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

  async copyText(event) {
    const btn = event.currentTarget
    const text = this.textValue

    if (!text) return

    try {
      await navigator.clipboard.writeText(text)

      // Show feedback
      const originalHTML = btn.innerHTML
      btn.innerHTML = `
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <polyline points="20 6 9 17 4 12"></polyline>
        </svg>
        Copied!
      `
      btn.classList.add("copied")

      setTimeout(() => {
        btn.innerHTML = originalHTML
        btn.classList.remove("copied")
      }, 2000)
    } catch {
      // Fallback for older browsers
      const textarea = document.createElement("textarea")
      textarea.value = text
      textarea.style.position = "fixed"
      textarea.style.opacity = "0"
      document.body.appendChild(textarea)
      textarea.select()
      document.execCommand("copy")
      document.body.removeChild(textarea)

      btn.textContent = "Copied!"
      setTimeout(() => {
        btn.textContent = "Share"
      }, 2000)
    }
  }
}
