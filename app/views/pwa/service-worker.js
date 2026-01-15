// Service Worker - Network Only (no offline support for ads)
// This PWA requires internet connection

self.addEventListener("install", () => {
  self.skipWaiting()
})

self.addEventListener("activate", (event) => {
  // Clear any existing caches
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => caches.delete(cacheName))
      )
    })
  )
  self.clients.claim()
})

// Network only - no caching, requires internet
self.addEventListener("fetch", (event) => {
  event.respondWith(fetch(event.request))
})
