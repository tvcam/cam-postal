import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["message", "charCount", "moods"]

  connect() {
    this.updateCount()
  }

  updateCount() {
    if (this.hasMessageTarget && this.hasCharCountTarget) {
      const length = this.messageTarget.value.length
      this.charCountTarget.textContent = length

      if (length > 450) {
        this.charCountTarget.classList.add("warning")
      } else {
        this.charCountTarget.classList.remove("warning")
      }

      if (length >= 500) {
        this.charCountTarget.classList.add("limit")
      } else {
        this.charCountTarget.classList.remove("limit")
      }
    }
  }

  selectMood(event) {
    const selected = event.target
    const options = this.moodsTarget.querySelectorAll(".mood-option")

    options.forEach(option => {
      option.classList.remove("selected")
    })

    selected.closest(".mood-option").classList.add("selected")
  }
}
