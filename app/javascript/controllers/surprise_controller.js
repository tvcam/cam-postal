import { Controller } from "@hotwired/stimulus"

const HISTORY_KEY = "surprise_history"
const MAX_HISTORY = 10

export default class extends Controller {
  static targets = ["button", "result", "categories", "historySection", "historyList", "progress", "confetti"]

  connect() {
    this.selectedCategory = "any"
    this.loadHistory()
    this.createConfettiCanvas()
  }

  disconnect() {
    if (this.confettiCanvas) {
      this.confettiCanvas.remove()
    }
  }

  createConfettiCanvas() {
    this.confettiCanvas = document.createElement("canvas")
    this.confettiCanvas.className = "confetti-canvas"
    this.confettiCanvas.style.cssText = `
      position: fixed;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      pointer-events: none;
      z-index: 9999;
      opacity: 0;
      transition: opacity 0.3s;
    `
    document.body.appendChild(this.confettiCanvas)
  }

  selectCategory(event) {
    const btn = event.currentTarget
    this.selectedCategory = btn.dataset.category

    // Update active state
    this.categoriesTarget.querySelectorAll(".category-btn").forEach(b => {
      b.classList.remove("active")
    })
    btn.classList.add("active")
  }

  async reveal() {
    const btn = this.buttonTarget
    btn.disabled = true
    btn.classList.add("spinning")

    try {
      const url = `/surprise/reveal?category=${this.selectedCategory}`
      const response = await fetch(url, {
        headers: {
          "Accept": "text/vnd.turbo-stream.html",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        }
      })

      if (response.ok) {
        const html = await response.text()
        // Parse the turbo stream and extract destination data
        const parser = new DOMParser()
        const doc = parser.parseFromString(html, "text/html")
        const card = doc.querySelector(".destiny-card")

        if (card) {
          // Extract data for history
          const name = card.querySelector(".destiny-name")?.textContent
          const code = card.querySelector(".destiny-code")?.textContent
          const emoji = card.querySelector(".destiny-emoji")?.textContent

          if (name && code) {
            this.addToHistory({ name, code, emoji, date: new Date().toISOString() })
          }
        }

        // Render the result
        this.resultTarget.innerHTML = doc.querySelector("template")?.innerHTML || html
        this.resultTarget.classList.add("revealed")

        // Trigger confetti celebration
        this.triggerConfetti()

        // Smooth scroll to result
        setTimeout(() => {
          this.resultTarget.scrollIntoView({ behavior: "smooth", block: "center" })
        }, 100)
      }
    } catch (error) {
      console.error("Failed to reveal:", error)
    } finally {
      btn.disabled = false
      btn.classList.remove("spinning")
    }
  }

  triggerConfetti() {
    const canvas = this.confettiCanvas
    const ctx = canvas.getContext("2d")

    // Set canvas size
    canvas.width = window.innerWidth
    canvas.height = window.innerHeight
    canvas.style.opacity = "1"

    const confettiColors = ["#fbbf24", "#f59e0b", "#ef4444", "#ec4899", "#8b5cf6", "#3b82f6", "#10b981"]
    const confettiPieces = []

    // Create confetti pieces
    for (let i = 0; i < 150; i++) {
      confettiPieces.push({
        x: Math.random() * canvas.width,
        y: Math.random() * canvas.height - canvas.height,
        w: Math.random() * 10 + 5,
        h: Math.random() * 6 + 4,
        color: confettiColors[Math.floor(Math.random() * confettiColors.length)],
        velocity: Math.random() * 3 + 2,
        angle: Math.random() * Math.PI * 2,
        angularVelocity: (Math.random() - 0.5) * 0.2,
        oscillationAmplitude: Math.random() * 3,
        oscillationSpeed: Math.random() * 0.02 + 0.01
      })
    }

    let frame = 0
    const maxFrames = 180 // ~3 seconds at 60fps

    const animate = () => {
      frame++
      ctx.clearRect(0, 0, canvas.width, canvas.height)

      confettiPieces.forEach(piece => {
        piece.y += piece.velocity
        piece.x += Math.sin(frame * piece.oscillationSpeed) * piece.oscillationAmplitude
        piece.angle += piece.angularVelocity

        ctx.save()
        ctx.translate(piece.x, piece.y)
        ctx.rotate(piece.angle)
        ctx.fillStyle = piece.color
        ctx.fillRect(-piece.w / 2, -piece.h / 2, piece.w, piece.h)
        ctx.restore()
      })

      if (frame < maxFrames) {
        requestAnimationFrame(animate)
      } else {
        // Fade out
        canvas.style.opacity = "0"
        setTimeout(() => {
          ctx.clearRect(0, 0, canvas.width, canvas.height)
        }, 300)
      }
    }

    animate()
  }

  // Web Share API for native sharing
  async shareResult(event) {
    const btn = event.currentTarget
    const shareText = btn.dataset.shareText

    if (!shareText) return

    // Try Web Share API first (mobile-friendly)
    if (navigator.share) {
      try {
        await navigator.share({
          title: "My Cambodia Destiny",
          text: shareText,
          url: window.location.href
        })
        this.showShareFeedback(btn, true)
        return
      } catch (err) {
        // User cancelled or share failed, fall through to clipboard
        if (err.name === "AbortError") return
      }
    }

    // Fallback to clipboard
    try {
      await navigator.clipboard.writeText(shareText)
      this.showShareFeedback(btn, false)
    } catch {
      // Final fallback
      const textarea = document.createElement("textarea")
      textarea.value = shareText
      textarea.style.position = "fixed"
      textarea.style.opacity = "0"
      document.body.appendChild(textarea)
      textarea.select()
      document.execCommand("copy")
      document.body.removeChild(textarea)
      this.showShareFeedback(btn, false)
    }
  }

  showShareFeedback(btn, wasShared) {
    const originalHTML = btn.innerHTML
    btn.innerHTML = `
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <polyline points="20 6 9 17 4 12"></polyline>
      </svg>
      ${wasShared ? "Shared!" : "Copied!"}
    `
    btn.classList.add("success")

    setTimeout(() => {
      btn.innerHTML = originalHTML
      btn.classList.remove("success")
    }, 2000)
  }

  addToHistory(item) {
    let history = this.getHistory()

    // Don't add duplicates from same day
    const today = new Date().toDateString()
    const isDuplicate = history.some(h =>
      h.code === item.code && new Date(h.date).toDateString() === today
    )

    if (!isDuplicate) {
      history.unshift(item)
      history = history.slice(0, MAX_HISTORY)
      localStorage.setItem(HISTORY_KEY, JSON.stringify(history))
      this.renderHistory()
    }
  }

  getHistory() {
    try {
      return JSON.parse(localStorage.getItem(HISTORY_KEY)) || []
    } catch {
      return []
    }
  }

  loadHistory() {
    this.renderHistory()
  }

  renderHistory() {
    const history = this.getHistory()

    if (!this.hasHistorySectionTarget) return

    if (history.length === 0) {
      this.historySectionTarget.style.display = "none"
      return
    }

    this.historySectionTarget.style.display = "block"

    // Render history items
    if (this.hasHistoryListTarget) {
      this.historyListTarget.innerHTML = history.slice(0, 5).map(item => {
        const date = new Date(item.date)
        const dateStr = this.formatDate(date)
        return `
          <a href="/p/${item.code}" class="history-item">
            <span class="history-emoji">${item.emoji || "📍"}</span>
            <span class="history-name">${item.name}</span>
            <span class="history-date">${dateStr}</span>
          </a>
        `
      }).join("")
    }

    // Render progress
    if (this.hasProgressTarget) {
      const uniqueProvinces = new Set(history.map(h => h.code?.slice(0, 2))).size
      this.progressTarget.innerHTML = `
        <div class="progress-bar">
          <div class="progress-fill" style="width: ${(uniqueProvinces / 25) * 100}%"></div>
        </div>
        <p class="progress-text">${uniqueProvinces}/25 provinces discovered</p>
      `
    }
  }

  formatDate(date) {
    const now = new Date()
    const diff = now - date
    const days = Math.floor(diff / (1000 * 60 * 60 * 24))

    if (days === 0) return "Today"
    if (days === 1) return "Yesterday"
    if (days < 7) return `${days} days ago`
    return date.toLocaleDateString()
  }

  clearHistory() {
    localStorage.removeItem(HISTORY_KEY)
    this.renderHistory()
  }
}
