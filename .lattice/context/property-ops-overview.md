---
feature: Property Ops Overview
requirement_doc: null
created: "2026-06-13"
---

# Property Ops Overview

> Redesign the property show page into the daily operations cockpit: lead with today's movements (arrivals / departures / in-house) as one vertical strip, then a visual room dashboard showing each room's state and occupancy. Folds the standalone per-property reservations "house view" into the property page.

## Decisions Log

<!-- Add new at bottom. Never remove. -->

| Date | Decision | Reasoning | Alternatives Considered |
|------|----------|-----------|------------------------|
| 2026-06-13 | Movements overview = three-column band (Arrivals / Departures / In-house) atop properties#show | User choice; compact vertically, scannable side-by-side | Single vertical feed; one-line summary |
| 2026-06-13 | Room dashboard = enhanced table (existing table + occupancy + stronger state coloring), not cards | User choice; lowest churn, occupancy column already exists | Grid of room cards; cards grouped by floor |
| 2026-06-13 | Remove ReservationsController#index + view; properties#show becomes the house view; "New reservation" moves to the property page | User choice; folds the house view in, single source of truth | Redirect index→show; keep both |
| 2026-06-13 | Lifecycle PATCH actions (check_in/check_out/cancel) and the AASM rescue now redirect to property_path, not property_reservations_path | reservations#index no longer exists | Keep redirecting to removed route |
| 2026-06-13 | Design approved at Level 4. Blueprint complete, ready for implementation | All four levels walked; user approved ("extend functionality later") | — |

## Constraints

<!-- Non-negotiable once recorded. Add only when confirmed. -->

- Builds on merged Properties & Rooms and Guests & Reservations. No schema changes expected — this is a presentation + read-query redesign.
- Rails MVC+ (architecture.md): queries as scopes/model methods, preload to avoid N+1, thin controller. All strings via I18n. Plain CSS tokens in application.css (no framework).
- Availability/occupancy stays derived from reservations, never stored.

## Design: Level 1 -- Capabilities

Approved 2026-06-13.

1. **Property page opens on today's movements** — a three-column band (Arrivals / Departures / In-house) with counts and the relevant lifecycle action per item.
2. **Room dashboard below** — the existing rooms table, enhanced: occupancy (guest name vs. free) + stronger per-state coloring.
3. **Book from the property page** — "New reservation" action lives here now.
4. **Standalone house view removed** — `reservations#index` + its view/route deleted; this page replaces it.

Out of scope: date-ranged history, multi-day forecast, drag/drop, Turbo Streams (still plain redirects).

## Design: Level 2 -- Components

Approved 2026-06-13. All existing layers; only new files are view partials.

| Component | Layer | Change |
|---|---|---|
| `PropertiesController#show` | Controllers | Absorb house-view query: `@arrivals`, `@departures`, `@in_house` (preloaded guest+room) alongside existing `@current_reservations` |
| `ReservationsController` | Controllers | Drop `index`; lifecycle actions + `rescue_from` redirect to `property_path` |
| `properties/show.html.erb` | Views | Rewrite: movements band + enhanced room table + New reservation button |
| `properties/_movement.html.erb` | Views | New partial — one movement row (guest, room, action) |
| `reservations/index.html.erb`, `reservations/_reservation.html.erb` | Views | Delete |
| routes / en.yml / application.css | — | Drop `:index`; move `reservations.index` strings under `properties.show`; add band + room-state styles |

No model/migration/service changes. Scopes `arriving_on`/`departing_on` already exist.

## Design: Level 3 -- Interactions

Approved 2026-06-13.

- **GET /properties/:id** → `show` loads property + rooms (current checked-in reservation preloaded for occupancy, no N+1) + today's three movement groups (preloaded `:guest, :room`). Renders band then table.
- **Lifecycle** (`PATCH check_in/check_out/cancel`, shallow routes unchanged) → redirect to `property_path(@reservation.room.property)`; `AASM::InvalidTransition` → same redirect + flash alert.
- **New reservation** → `new_property_reservation_path`; on success redirect to `property_path`; `reservations/new` back link → `property_path`.
- Band items render their available action via existing `may_*?` guards (arrivals→check in, departures/in-house→check out where legal). In-house extension deferred (user: "extend later").

## Design: Level 4 -- Contracts

Approved 2026-06-13.

- **`PropertiesController#show`** sets `@property`, `@current_reservations` (Hash room_id→Reservation), `@arrivals` = `@property.reservations.arriving_on(Date.current)`, `@departures` = `departing_on`, `@in_house` = `checked_in` — each `.includes(:guest, :room)`.
- **Routes:** `resources :reservations, only: %i[ new create ]` (members unchanged).
- **Redirect target change** in `create`, `check_in`, `check_out`, `cancel`, `rescue_from` → `property_path`.
- **i18n:** add `properties.show.{today, arrivals, departures, in_house, empty_arrivals, empty_departures, empty_in_house, new_reservation}`; remove `reservations.index.*`; keep `reservations.actions.*` (used by `_movement`).
- **Specs:** delete `reservations#index` request spec; add `properties#show` spec asserting band groups + occupancy; update lifecycle specs to expect `property_path` redirects.

Failure modes unchanged: illegal transition → redirect + flash; booking conflict/invalid → 422 re-render of `reservations/new`.

## Design Summary

**Status: Approved -- ready for implementation** (2026-06-13)

- **Components/layers**: `PropertiesController#show` (absorbs house-view query), `ReservationsController` (drops `index`, redirects to `property_path`), rewritten `properties/show.html.erb` + new `properties/_movement` partial; deleted `reservations/index` + `_reservation`. CSS + i18n updates. No model/service/schema changes.
- **Key contracts**: show-action ivars (arrivals/departures/in_house/current_reservations); reservations routes drop `:index`; five redirect targets change to `property_path`.
- **Architectural constraints**: queries via existing scopes, preload to avoid N+1, thin controller, all strings I18n, plain CSS tokens.
- **Domain decisions**: occupancy/movements stay derived from reservations; in-house band action extension deferred.
- **Next step**: `/code-forge` against this blueprint.

## Key Files

Implemented 2026-06-13 (`/code-forge`):

- `app/controllers/properties_controller.rb` — `#show` now also loads `@arrivals`/`@departures`/`@in_house` (preloaded guest+room) for the band.
- `app/controllers/reservations_controller.rb` — `index` removed; `create` + lifecycle actions + `rescue_from` redirect to `property_path`.
- `app/views/properties/show.html.erb` — rewritten: movements band + enhanced room table + New reservation.
- `app/views/properties/_movement.html.erb` — new; one movement row with its lifecycle action (via `may_*?` guards).
- `app/views/reservations/{index,_reservation}.html.erb` — deleted.
- `app/views/rooms/_room.html.erb` — row gains `room-row room-row-<status>` for the state stripe.
- `app/assets/stylesheets/application.css` — `.movements*` band + `.room-row-*` state stripe/tint.
- `config/routes.rb` — reservations `only: %i[ new create ]`.
- `config/locales/en.yml` — `properties.show.{today,arrivals,departures,in_house,empty_*,new_reservation}`; `reservations.index.*` removed; `reservations.new.back` → property.
- Specs: `spec/requests/properties_spec.rb` (band + occupancy), `spec/requests/reservations_spec.rb` (index test removed, redirects → `property_path`). Full suite green (82 examples).
