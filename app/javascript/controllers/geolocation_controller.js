import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "status"]
  static outlets = ["search"]

  locate() {
    if (!navigator.geolocation) {
      this.showStatus("Geolocation not supported by your browser")
      return
    }

    this.buttonTarget.disabled = true
    this.showStatus("Getting your location...")

    navigator.geolocation.getCurrentPosition(
      (position) => this.onSuccess(position),
      (error) => this.onError(error),
      { enableHighAccuracy: true, timeout: 10000 }
    )
  }

  async onSuccess(position) {
    const { latitude, longitude } = position.coords
    this.showStatus("Finding postal code...")

    try {
      const response = await fetch(`/locate?lat=${latitude}&lng=${longitude}`)
      const data = await response.json()

      if (data.error) {
        this.showStatus(data.error)
      } else if (data.postal_code) {
        this.searchFor(data.postal_code)
        this.showStatus(`Found: ${data.postal_code}`)
      } else if (data.area) {
        this.searchFor(data.area)
        this.showStatus(`Searching for: ${data.area}`)
      } else {
        this.showStatus("Could not determine postal code for this location")
      }
    } catch {
      this.showStatus("Error looking up location")
    } finally {
      this.buttonTarget.disabled = false
    }
  }

  onError(error) {
    this.buttonTarget.disabled = false
    switch (error.code) {
      case error.PERMISSION_DENIED:
        this.showStatus("Location permission denied")
        break
      case error.POSITION_UNAVAILABLE:
        this.showStatus("Location unavailable")
        break
      case error.TIMEOUT:
        this.showStatus("Location request timed out")
        break
      default:
        this.showStatus("Error getting location")
    }
  }

  searchFor(query) {
    if (this.hasSearchOutlet) {
      this.searchOutlet.inputTarget.value = query
      this.searchOutlet.search()
    }
  }

  showStatus(message) {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = message
      this.statusTarget.classList.add("visible")
      setTimeout(() => {
        this.statusTarget.classList.remove("visible")
      }, 3000)
    }
  }
}
