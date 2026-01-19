import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  flag(event) {
    event.preventDefault()

    if (!confirm("Report this message as inappropriate?")) {
      return
    }

    const url = this.urlValue || event.currentTarget.dataset.capsuleUrlValue

    fetch(url, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Accept": "text/vnd.turbo-stream.html"
      }
    }).then(response => {
      if (response.ok) {
        // Remove the capsule element directly
        this.element.remove()
      }
    }).catch(() => {})
  }
}
