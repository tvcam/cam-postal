# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Rules

- **Never include Co-Authored-By lines in git commits** - Do not add "Co-Authored-By: Claude" or any AI attribution in commit messages
- **Ask for commit & deploy when changes are complete** - After completing a feature or fix, ask the user if they want to commit and deploy using `kamal deploy`
- **Always run linters before committing** - Run both Ruby and JS linters before any git commit:
  - `bin/rubocop -A` for Ruby (auto-fix)
  - `npm run lint:fix` for JavaScript (auto-fix)

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

### Natural Language Understanding (NLU)

**Why NLU?**
Users often search using natural language questions like "postal code for Siem Reap" or "communes in Phnom Penh" instead of simple keywords. The NLU feature understands these queries and provides more accurate, contextual results.

**How It Works**:
```
User Query → NLU Detection → [Cache Check] → Claude API → Intent Extraction → Query Executor → Results
```

1. **Detection**: Queries are checked for natural language patterns (question words, "code for", "in/of/near")
2. **Caching**: Parsed intents are cached in `nlu_caches` table to minimize API calls (~80% cache hit rate)
3. **Parsing**: Claude 3 Haiku extracts intent type, location names, and confidence score
4. **Execution**: `NluQueryExecutor` translates intents into appropriate database queries
5. **Fallback**: If NLU fails or confidence < 0.7, falls back to regular FTS search

**Intent Types**:
- `search_location`: Direct location search ("postal code for Siem Reap")
- `list_by_parent`: List children of a parent ("communes in Phnom Penh")
- `search_landmark`: Search by landmark name ("near Angkor Wat")
- `search_nearby`: Find nearby locations

**Key Files**:
- `app/services/nlu_search_service.rb` - Claude API integration
- `app/services/nlu_query_executor.rb` - Intent execution
- `app/models/nlu_cache.rb` - Response caching

**Configuration**:
Add Anthropic API key to credentials:
```bash
EDITOR=vim bin/rails credentials:edit
```
```yaml
anthropic:
  api_key: sk-ant-...
```

**Rake Tasks**:
```bash
rake nlu:stats              # View cache statistics
rake nlu:test['your query'] # Test NLU parsing
rake nlu:warm               # Pre-warm cache
rake nlu:cleanup            # Remove stale entries
```

**Cost**: ~$0.00009 per query (~9 cents per 1000 queries), with caching reducing costs further

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
