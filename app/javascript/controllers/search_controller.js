import { Controller } from "@hotwired/stimulus"
import Fuse from "fuse.js"
import LZString from "lz-string"

const STORAGE_KEY = "postal_data_v8"
const RECENT_KEY = "recent_searches"
const DATA_URL = "/data.json"
const MAX_RECENT = 8

export default class extends Controller {
  static targets = ["input", "results", "frame", "form"]
  static values = { translations: Object }

  connect() {
    this.timeout = null
    this.fuse = null
    this.aliases = {}
    this.clientMode = false
    this.lastQuery = ""
    this.t = this.translationsValue || {}
    this.loadData()
  }

  async loadData() {
    // Try compressed cache first
    const cached = this.getFromStorage()
    if (cached) {
      console.log("[Search Debug] Loaded from cache:", cached.data?.length || 0, "records,", Object.keys(cached.aliases || {}).length, "aliases")
      this.aliases = cached.aliases || {}
      this.initFuse(cached.data || cached)
      return
    }

    // Fetch fresh data
    console.log("[Search Debug] Fetching fresh data from", DATA_URL)
    try {
      const response = await fetch(DATA_URL)
      const json = await response.json()
      // Handle both old format (array) and new format ({ data, aliases })
      const data = json.data || json
      this.aliases = json.aliases || {}
      console.log("[Search Debug] Fetched:", data.length, "records,", Object.keys(this.aliases).length, "aliases")
      this.saveToStorage({ data, aliases: this.aliases })
      this.initFuse(data)
    } catch (e) {
      // Client search unavailable, will use server fallback
      console.error("[Search Debug] Failed to load data:", e)
    }
  }

  getFromStorage() {
    try {
      const compressed = localStorage.getItem(STORAGE_KEY)
      if (!compressed) return null
      const json = LZString.decompressFromUTF16(compressed)
      const parsed = JSON.parse(json)
      // Ensure we have the new format with aliases
      if (parsed && parsed.data && parsed.aliases) {
        return parsed
      }
      // Old format - clear and refetch
      localStorage.removeItem(STORAGE_KEY)
      return null
    } catch {
      return null
    }
  }

  saveToStorage(payload) {
    try {
      const json = JSON.stringify(payload)
      const compressed = LZString.compressToUTF16(json)
      localStorage.setItem(STORAGE_KEY, compressed)
    } catch {
      // Storage unavailable
    }
  }

  initFuse(data) {
    console.log("[Search Debug] Initializing Fuse with", data.length, "records")
    // Log sample records to verify data format
    if (data.length > 0) {
      console.log("[Search Debug] Sample record:", JSON.stringify(data[0]))
    }
    this.fuse = new Fuse(data, {
      keys: [
        { name: "code", weight: 2.0 },
        { name: "name_en", weight: 1.5 },
        { name: "name_km", weight: 1.5 },
        { name: "parent", weight: 0.3 }
      ],
      threshold: 0.35,
      distance: 100,
      ignoreLocation: true,
      minMatchCharLength: 2
    })
    this.enableClientMode()
  }

  // Resolve alias to official name
  resolveAlias(query) {
    if (!query || !this.aliases) return query
    const normalized = query.toLowerCase().trim()
    return this.aliases[normalized] || query
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

  search(options = {}) {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      const query = this.inputTarget.value.trim()
      const limit = options.limit || null

      // Use server-side search for NLU queries
      if (this.shouldUseNlu(query)) {
        this.serverSearch(query)
        return
      }

      if (this.clientMode && this.fuse) {
        this.clientSearch(query, limit)
      } else {
        // Server fallback - find form and submit
        const form = this.element.querySelector("form")
        if (form) form.requestSubmit()
      }
    }, this.clientMode ? 100 : 300)
  }

  // Detect natural language queries that should use NLU
  shouldUseNlu(query) {
    if (!query || query.length < 5) return false
    if (/^\d{2,6}$/.test(query)) return false // Pure postal code

    const nluPatterns = [
      /\b(what|where|which|how|find|get|show)\b/i,
      /\b(postal\s*code|zip\s*code)\s+(for|of|in)\b/i,
      /\b(communes?|districts?|provinces?)\s+(in|of|for)\b/i,
      /\bnear\b/i,
      /\bcode\s+for\b/i
    ]

    return nluPatterns.some(pattern => pattern.test(query))
  }

  // Send query to server for NLU processing
  serverSearch(query) {
    // Show loading state
    if (this.hasResultsTarget) {
      const loadingText = this.t.ai_thinking || "Understanding your question..."
      this.resultsTarget.innerHTML = `
        <div class="results-section">
          <div class="nlu-loading">
            <div class="nlu-spinner"></div>
            <p>${loadingText}</p>
          </div>
          ${this.sloganTemplate()}
        </div>`
    }

    // Submit form for server-side processing
    const form = this.element.querySelector("form")
    if (form) form.requestSubmit()
  }

  clientSearch(query, limit = null) {
    if (!query) {
      this.renderWelcome()
      return
    }

    console.log("[Search Debug] Searching for:", query)

    // Try alias resolution first
    const resolved = this.resolveAlias(query)
    const searchTerm = resolved !== query ? resolved : query
    if (resolved !== query) {
      console.log("[Search Debug] Alias resolved:", query, "->", resolved)
    }

    const maxResults = limit || 50
    const results = this.fuse.search(searchTerm, { limit: maxResults })
    console.log("[Search Debug] Found", results.length, "results for:", searchTerm)
    if (results.length > 0) {
      console.log("[Search Debug] Top result:", JSON.stringify(results[0].item))
    }
    this.renderResults(results.map(r => r.item), query)

    // Save to recent searches if results found
    if (results.length > 0) {
      this.saveRecentSearch(query)
    }

    // Track search stat (fire and forget)
    if (query !== this.lastQuery) {
      this.lastQuery = query
      this.trackSearch(query)
    }
  }

  trackSearch(query) {
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    fetch("/track/search", {
      method: "POST",
      headers: {
        "X-CSRF-Token": token,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({ q: query })
    }).catch(() => {})
  }

  renderResults(items, query) {
    if (!this.hasResultsTarget) return

    const noResultsText = this.t.no_results || "No results found for"

    if (!items.length) {
      this.resultsTarget.innerHTML = `
        <div class="results-section">
          <div class="no-results"><p>${noResultsText} "${this.escapeHtml(query)}"</p></div>
          ${this.sloganTemplate()}
        </div>`
      return
    }

    const countText = items.length === 1
      ? (this.t.found_results_one || "Found 1 result")
      : (this.t.found_results_other || `Found ${items.length} results`).replace("%{count}", items.length)

    this.resultsTarget.innerHTML = `
      <div class="results-section">
        <p class="results-count">${countText}</p>
        <div class="results-list">
          ${items.map(item => this.cardTemplate(item, query)).join("")}
        </div>
        ${this.sloganTemplate()}
      </div>`
  }

  sloganTemplate() {
    const sloganKm = this.t.slogan_km || "🇰🇭 សាមគ្គីជាកម្លាំង 🇰🇭"
    const sloganEn = this.t.slogan_en || "Unity is Strength"
    return `
      <div class="unity-slogan">
        <p class="slogan-km">${sloganKm}</p>
        <p class="slogan-en">${sloganEn}</p>
      </div>`
  }

  cardTemplate(item, query) {
    const types = {
      province: this.t.province || "Province",
      district: this.t.district || "District",
      commune: this.t.commune || "Commune"
    }
    const copyHint = this.t.click_to_copy || "Click to copy"
    return `
      <div class="result-card ${item.type}" data-controller="copy" data-copy-text-value="${item.code}" data-action="click->copy#copy">
        <div class="result-header">
          <span class="postal-code">${item.code}</span>
          <span class="location-type ${item.type}">${types[item.type] || item.type}</span>
        </div>
        <div class="result-body">
          <p class="name-en">${this.highlight(item.name_en, query)}</p>
          ${item.name_km ? `<p class="name-km">${this.highlight(item.name_km, query)}</p>` : ""}
          ${item.parent ? `<p class="parent-location">${item.parent}</p>` : ""}
        </div>
        <span class="copy-hint">${copyHint}</span>
      </div>`
  }

  renderWelcome() {
    if (!this.hasResultsTarget) return
    const recent = this.getRecentSearches()
    const welcomeText = this.t.welcome || "Enter a search term to find postal codes"

    if (recent.length === 0) {
      this.resultsTarget.innerHTML = `
        <div class="results-section">
          <div class="welcome-message"><p>${welcomeText}</p></div>
          ${this.sloganTemplate()}
        </div>`
      return
    }

    const recentTitle = this.t.recent_searches || "Recent searches"
    this.resultsTarget.innerHTML = `
      <div class="results-section">
        <div class="recent-searches">
          <p class="recent-title">${recentTitle}</p>
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
    } catch {
      // Storage unavailable - ignore
    }
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
