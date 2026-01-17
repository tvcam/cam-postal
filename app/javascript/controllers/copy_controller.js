import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { text: String }

  copy() {
    navigator.clipboard.writeText(this.textValue).then(() => {
      this.element.classList.add("copied")
      setTimeout(() => {
        this.element.classList.remove("copied")
      }, 1500)

      // Track copy event
      fetch("/track_copy", {
        method: "POST",
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        }
      }).catch(() => {})
    })
  }

  // Copy and prevent navigation (for links)
  copyAndPrevent(event) {
    event.preventDefault()
    this.copy()
  }
}
