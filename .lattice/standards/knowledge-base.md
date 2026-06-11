---
feature: "Iris Knowledge Base"
mode: override
created: "2026-06-11"
---

> This is the knowledge base for Iris. It primes AI with project-specific context -- tech stack, architecture, trusted sources, and project structure -- so generated code fits this codebase rather than defaulting to generic patterns.

## 1. Architecture Overview

Iris is a hotel Property Management System (PMS) -- a personal/showcase project, single developer.

- Classic server-rendered **Rails monolith** (MVC + Hotwire). No SPA, no separate API service.
- Single shared **SQLite** database; background jobs, cache, and websockets are DB-backed via the Solid trifecta (no Redis, no external brokers).
- Core domain: **properties (hotels) → rooms**, **guests → reservations**, and **maintenance requests** per room.
- Users are hotel staff; authentication via Rails 8 built-in session auth.
- No external integrations in v1 (no channel managers, payment gateways, or OTA syncing).

## 2. Tech Stack and Versions

- **Runtime**: Ruby 3.4.9 (rbenv; `.ruby-version` at `code/ruby/`)
- **Framework**: Rails 8.1.3
- **Database**: SQLite 3 via `sqlite3` gem >= 2.1 (not PostgreSQL/MySQL) -- also the production target, Rails 8 style
- **Frontend**: Hotwire -- Turbo + Stimulus, importmap-rails (no Node, no JS bundler), Propshaft (not Sprockets), plain CSS (no Tailwind)
- **Jobs / cache / cable**: Solid Queue / Solid Cache / Solid Cable (DB-backed, not Sidekiq/Redis)
- **Auth**: Rails 8 built-in authentication generator -- sessions + bcrypt (not Devise)
- **Testing**: RSpec (rspec-rails 8.x) + FactoryBot (not Minitest, not fixtures)
- **Lint / security**: RuboCop `rails-omakase`, Brakeman, bundler-audit
- **Server**: Puma (+ Thruster in production)

## 3. Curated Knowledge Sources

| Topic | Source | Why We Trust It |
|-------|--------|-----------------|
| Rails framework | https://guides.rubyonrails.org (8.1) | Official, version-matched |
| Rails API | https://api.rubyonrails.org | Authoritative method-level reference |
| Turbo | https://turbo.hotwired.dev/handbook | Official Hotwire handbook |
| Stimulus | https://stimulus.hotwired.dev/handbook | Official Hotwire handbook |
| RSpec Rails | https://rspec.info/features/8-0/rspec-rails | Matches rspec-rails 8.x |
| FactoryBot | https://github.com/thoughtbot/factory_bot/blob/main/GETTING_STARTED.md | Canonical factory patterns |

## 4. Project Structure

Standard Rails 8 layout with `spec/` instead of `test/`:

```
app/
+-- controllers/       # HTTP layer, thin
+-- models/            # ActiveRecord models + domain POROs
+-- views/             # ERB templates (Turbo-aware partials)
+-- javascript/        # Stimulus controllers (importmap)
+-- jobs/              # Solid Queue jobs
config/                # Routes, env config, queue/cache/cable yml
db/                    # Migrations, schema + solid_* schemas
spec/                  # RSpec (models/, requests/, system/, factories/)
.lattice/              # Lattice standards, context docs, learnings
```

## 5. Project Conventions

- FactoryBot is included in RSpec config (`create`/`build` available without the `FactoryBot.` prefix).
- Feature-level decisions are captured in `.lattice/context/` documents, not in code comments.

---
*Generated for Iris on 2026-06-11. Mode: override.*
*Produced by the knowledge-priming-refiner skill.*
