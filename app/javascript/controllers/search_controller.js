import { Controller } from "@hotwired/stimulus"
import Fuse from "fuse.js"
import LZString from "lz-string"

const STORAGE_KEY = "postal_data_v1"
const RECENT_KEY = "recent_searches"
const DATA_URL = "/data.json"
const MAX_RECENT = 8

export default class extends Controller {
  static targets = ["input", "results", "frame", "form"]

  connect() {
    this.timeout = null
    this.fuse = null
    this.clientMode = false
    this.lastQuery = ""
    this.loadData()
  }

  async loadData() {
    // Try compressed cache first
    const cached = this.getFromStorage()
    if (cached) {
      this.initFuse(cached)
      return
    }

    // Fetch fresh data
    try {
      const response = await fetch(DATA_URL)
      const data = await response.json()
      this.saveToStorage(data)
      this.initFuse(data)
    } catch (e) {
      console.warn("Client search unavailable:", e)
    }
  }

  getFromStorage() {
    try {
      const compressed = localStorage.getItem(STORAGE_KEY)
      if (!compressed) return null
      const json = LZString.decompressFromUTF16(compressed)
      return JSON.parse(json)
    } catch {
      return null
    }
  }

  saveToStorage(data) {
    try {
      const json = JSON.stringify(data)
      const compressed = LZString.compressToUTF16(json)
      localStorage.setItem(STORAGE_KEY, compressed)
    } catch (e) {
      console.warn("Storage failed:", e)
    }
  }

  initFuse(data) {
    this.fuse = new Fuse(data, {
      keys: [
        { name: "c", weight: 2.0 },
        { name: "e", weight: 1.5 },
        { name: "k", weight: 1.5 },
        { name: "p", weight: 0.3 }
      ],
      threshold: 0.35,
      distance: 100,
      ignoreLocation: true,
      minMatchCharLength: 2
    })
    this.enableClientMode()
  }

  enableClientMode() {
    this.clientMode = true
    if (this.hasFrameTarget) {
      this.frameTarget.style.display = "none"
    }
    if (this.hasResultsTarget) {
      this.resultsTarget.style.display = "block"
    }
    // Render initial state based on current input
    const query = this.hasInputTarget ? this.inputTarget.value.trim() : ""
    if (query) {
      this.clientSearch(query)
    } else {
      this.renderWelcome()
    }
  }

  search() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      const query = this.inputTarget.value.trim()

      if (this.clientMode && this.fuse) {
        this.clientSearch(query)
      } else {
        // Server fallback - find form and submit
        const form = this.element.querySelector("form")
        if (form) form.requestSubmit()
      }
    }, this.clientMode ? 100 : 300)
  }

  clientSearch(query) {
    if (!query) {
      this.renderWelcome()
      return
    }

    const results = this.fuse.search(query, { limit: 50 })
    this.renderResults(results.map(r => r.item), query)

    // Save to recent searches if results found
    if (results.length > 0) {
      this.saveRecentSearch(query)
    }

    // Track search stat (fire and forget)
    if (query !== this.lastQuery) {
      this.lastQuery = query
      this.trackSearch()
    }
  }

  trackSearch() {
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    fetch("/track_search", {
      method: "POST",
      headers: { "X-CSRF-Token": token }
    }).catch(() => {})
  }

  renderResults(items, query) {
    if (!this.hasResultsTarget) return

    if (!items.length) {
      this.resultsTarget.innerHTML = `
        <div class="results-section">
          <div class="no-results"><p>No results found for "${this.escapeHtml(query)}"</p></div>
          ${this.sloganTemplate()}
        </div>`
      return
    }

    this.resultsTarget.innerHTML = `
      <div class="results-section">
        <p class="results-count">Found ${items.length} result${items.length === 1 ? "" : "s"}</p>
        <div class="results-list">
          ${items.map(item => this.cardTemplate(item, query)).join("")}
        </div>
        ${this.sloganTemplate()}
      </div>`
  }

  sloganTemplate() {
    return `
      <div class="unity-slogan">
        <p class="slogan-km">🇰🇭 សាមគ្គីជាកម្លាំង 🇰🇭</p>
        <p class="slogan-en">Unity is Strength</p>
      </div>`
  }

  cardTemplate(item, query) {
    const types = { province: "Province", district: "District", commune: "Commune" }
    return `
      <div class="result-card ${item.t}" data-controller="copy" data-copy-text-value="${item.c}" data-action="click->copy#copy">
        <div class="result-header">
          <span class="postal-code">${item.c}</span>
          <span class="location-type ${item.t}">${types[item.t] || item.t}</span>
        </div>
        <div class="result-body">
          <p class="name-en">${this.highlight(item.e, query)}</p>
          ${item.k ? `<p class="name-km">${this.highlight(item.k, query)}</p>` : ""}
          ${item.p ? `<p class="parent-location">${item.p}</p>` : ""}
        </div>
        <span class="copy-hint">Click to copy</span>
      </div>`
  }

  renderWelcome() {
    if (!this.hasResultsTarget) return
    const recent = this.getRecentSearches()

    if (recent.length === 0) {
      this.resultsTarget.innerHTML = `
        <div class="results-section">
          <div class="welcome-message"><p>Enter a search term to find postal codes</p></div>
          ${this.sloganTemplate()}
        </div>`
      return
    }

    this.resultsTarget.innerHTML = `
      <div class="results-section">
        <div class="recent-searches">
          <p class="recent-title">Recent searches</p>
          <div class="recent-list">
            ${recent.map(item => `
              <button type="button" class="recent-item" data-action="click->search#selectRecent" data-query="${this.escapeHtml(item)}">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <circle cx="12" cy="12" r="10"/>
                  <polyline points="12 6 12 12 16 14"/>
                </svg>
                ${this.escapeHtml(item)}
              </button>
            `).join("")}
          </div>
        </div>
        ${this.sloganTemplate()}
      </div>`
  }

  getRecentSearches() {
    try {
      return JSON.parse(localStorage.getItem(RECENT_KEY)) || []
    } catch {
      return []
    }
  }

  saveRecentSearch(query) {
    if (!query || query.length < 2) return
    try {
      let recent = this.getRecentSearches()
      // Remove if exists, add to front
      recent = recent.filter(q => q.toLowerCase() !== query.toLowerCase())
      recent.unshift(query)
      // Keep only MAX_RECENT
      recent = recent.slice(0, MAX_RECENT)
      localStorage.setItem(RECENT_KEY, JSON.stringify(recent))
    } catch {}
  }

  selectRecent(event) {
    const query = event.currentTarget.dataset.query
    if (this.hasInputTarget) {
      this.inputTarget.value = query
      this.inputTarget.focus()
      this.clientSearch(query)
    }
  }

  highlight(text, query) {
    if (!text || !query) return text || ""
    const terms = query.split(/\s+/).filter(t => t.length > 0)
    let result = text
    terms.forEach(term => {
      const escaped = term.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
      result = result.replace(new RegExp(`(${escaped})`, "gi"), "<mark>$1</mark>")
    })
    return result
  }

  escapeHtml(str) {
    return str.replace(/[&<>"']/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]))
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}
