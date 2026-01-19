import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { text: String }

  copy() {
    const postalCode = this.textValue
    navigator.clipboard.writeText(postalCode).then(() => {
      this.element.classList.add("copied")
      setTimeout(() => {
        this.element.classList.remove("copied")
      }, 1500)

      // Get current search query from search input
      const searchInput = document.querySelector('[data-search-target="input"]')
      const query = searchInput?.value?.trim() || ""

      // Track copy event with query and postal code for learned aliases
      fetch("/track/copy", {
        method: "POST",
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
          "Content-Type": "application/json"
        },
        body: JSON.stringify({ q: query, code: postalCode })
      }).catch(() => {})
    })
  }

  // Copy and prevent navigation (for links)
  copyAndPrevent(event) {
    event.preventDefault()
    this.copy()
  }
}
