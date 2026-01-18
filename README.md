# Cambodia Postal Code Directory

A fast, bilingual (English/Khmer) web application for searching Cambodian postal codes across all 25 provinces, districts, and communes.

**Live site:** https://cam-postal.gotabs.net

## Features

- **Instant Search** - Client-side Fuse.js fuzzy search (~10ms response time)
- **Bilingual Support** - English and Khmer names for all locations
- **Offline Ready** - PWA with service worker caching
- **Mobile Optimized** - Responsive design with touch-friendly UI
- **GPS Location** - Find nearby postal codes using geolocation
- **Recent Searches** - Quick access to previous searches (localStorage)
- **Dark Mode** - System-aware theme switching
- **SEO Optimized** - Server-side rendering, structured data, browsable location pages

## Tech Stack

- **Framework:** Ruby on Rails 8.1
- **Database:** SQLite 3 with FTS5 full-text search
- **Frontend:** Hotwire (Turbo + Stimulus), ImportMap
- **Search:** Fuse.js (client-side), FTS5 (server fallback)
- **Deployment:** Docker + Kamal

## Development

### Prerequisites

- Ruby 3.3.6
- SQLite 3

### Setup

```bash
bin/setup              # Install dependencies and prepare database
bin/dev                # Start development server (localhost:3000)
```

### Commands

```bash
bin/rails test         # Run unit tests
bin/rails test:system  # Run browser tests (Capybara)
bin/ci                 # Full CI pipeline (lint, security, tests)
bin/rubocop -A         # Lint with auto-fix
bin/brakeman --quiet   # Security scan
```

## Data

Postal codes sourced from official Cambodia Post data:
- 25 provinces
- 200+ districts
- 1,600+ communes
- 2,231 total postal codes

## Deployment

Deployed via Kamal to a single VPS with Docker:

```bash
kamal deploy           # Deploy to production
kamal app logs         # View production logs
```

## Project Structure

```
app/
├── controllers/
│   └── postal_codes_controller.rb    # Search, data API, location pages
├── models/
│   └── postal_code.rb                # FTS5 search, location hierarchy
├── javascript/controllers/
│   ├── search_controller.js          # Client-side Fuse.js search
│   ├── geolocation_controller.js     # GPS location lookup
│   ├── theme_controller.js           # Dark mode toggle
│   └── install_controller.js         # PWA install prompt
└── views/
    ├── postal_codes/                 # Search UI, location pages
    └── pwa/                          # Service worker, manifest
```

## License

MIT

## Author

[Gotabs Consulting](https://gotabs.net)
