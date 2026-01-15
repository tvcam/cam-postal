import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button"]

  connect() {
    this.deferredPrompt = null

    // Hide button initially
    if (this.hasButtonTarget) {
      this.buttonTarget.style.display = "none"
    }

    // Listen for beforeinstallprompt
    window.addEventListener("beforeinstallprompt", (e) => {
      e.preventDefault()
      this.deferredPrompt = e
      this.showButton()
    })

    // Hide after install
    window.addEventListener("appinstalled", () => {
      this.hideButton()
      this.deferredPrompt = null
    })

    // Check if already installed (standalone mode)
    if (window.matchMedia("(display-mode: standalone)").matches) {
      this.hideButton()
    }
  }

  showButton() {
    if (this.hasButtonTarget) {
      this.buttonTarget.style.display = "inline-flex"
    }
  }

  hideButton() {
    if (this.hasButtonTarget) {
      this.buttonTarget.style.display = "none"
    }
  }

  async install() {
    if (!this.deferredPrompt) return

    this.deferredPrompt.prompt()
    const { outcome } = await this.deferredPrompt.userChoice

    if (outcome === "accepted") {
      this.hideButton()
    }
    this.deferredPrompt = null
  }
}
