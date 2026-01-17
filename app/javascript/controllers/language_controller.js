import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropdown", "menu"]

  connect() {
    // Close dropdown when clicking outside
    document.addEventListener("click", this.handleClickOutside.bind(this))
  }

  disconnect() {
    document.removeEventListener("click", this.handleClickOutside.bind(this))
  }

  toggle(event) {
    event.stopPropagation()
    const dropdown = this.dropdownTarget
    const isHidden = dropdown.style.display === "none"
    dropdown.style.display = isHidden ? "block" : "none"
  }

  handleClickOutside(event) {
    if (!this.menuTarget.contains(event.target)) {
      this.dropdownTarget.style.display = "none"
    }
  }
}
