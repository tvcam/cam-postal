# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Rules

- **Never include Co-Authored-By lines in git commits** - Do not add "Co-Authored-By: Claude" or any AI attribution in commit messages
- **Ask for commit & deploy when changes are complete** - After completing a feature or fix, ask the user if they want to commit and deploy using `kamal deploy`

## Project Overview

Cambodia Postal Code Search - a Rails 8.1 web application for searching Cambodian postal codes (provinces, districts, communes) with bilingual support (English and Khmer).

## Development Commands

```bash
bin/setup              # Initial setup (bundle install, db:prepare)
bin/dev                # Start development server
bin/rails test         # Run unit tests
bin/rails test:system  # Run system tests (Capybara + Selenium)
bin/ci                 # Run full CI pipeline (lint, security, tests)
bin/rubocop -A         # Lint with auto-fix
bin/brakeman --quiet   # Security scan
```

## Architecture

### Tech Stack
- **Framework**: Rails 8.1.1, Ruby 3.3.6
- **Database**: SQLite 3 with FTS5 full-text search
- **Frontend**: Hotwire (Turbo + Stimulus), ImportMap, Propshaft
- **Deployment**: Docker + Kamal

### Key Components

**Model** (`app/models/postal_code.rb`):
- Uses FTS5 virtual table (`postal_codes_fts`) for fuzzy prefix matching with BM25 ranking
- Falls back to LIKE queries if FTS fails
- Location types: `province`, `district`, `commune`

**Search Flow**:
1. User types in search box → Stimulus controller debounces (300ms)
2. Turbo Frame requests `/search` endpoint
3. `PostalCodesController#search` queries FTS5 or falls back to LIKE
4. Results rendered as Turbo Stream partial

**Database**:
- FTS5 virtual table synced via triggers (INSERT/UPDATE/DELETE)
- Migration creates both `postal_codes` table and `postal_codes_fts` virtual table

### Routes
- `GET /` - Main search page
- `GET /search` - AJAX search endpoint (HTML partial or Turbo Stream)
- `GET /up` - Health check

## Testing

Uses Rails TestUnit with parallel execution:
- `test/models/` - Model tests
- `test/controllers/` - Controller tests
- `test/system/` - Browser tests (Capybara)

## Linting & Security

- **RuboCop**: Uses `rubocop-rails-omakase` preset
- **Brakeman**: Rails security scanner
- **Bundler-audit**: Dependency vulnerability checks

## Deployment

Kamal-based Docker deployment configured in `config/deploy.yml`. SQLite database persists via volume mount.
