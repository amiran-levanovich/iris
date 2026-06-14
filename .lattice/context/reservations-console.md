---
feature: Reservations Console & Booking
requirement_doc: null
created: "2026-06-13"
---

# Reservations Console & Booking

> Turn the property page into a tabbed console — a filterable, searchable reservations list (with today's movements strip on top) as the default tab, and the room dashboard moved to a "Housekeeping" tab. Fix and modernize the booking form: one interactive form whose room list re-filters on date change without losing selections, and a guest search-bar with inline create.

## Decisions Log

<!-- Add new at bottom. Never remove. -->

| Date | Decision | Reasoning | Alternatives Considered |
|------|----------|-----------|------------------------|
| 2026-06-13 | "Root" in req #4 = the property page's default tab; app home stays the hotel list | User note ("rooms tab is called housekeeping") implies tabs on the property page, not a global app-home reservations list | Global all-properties reservations list at app root |
| 2026-06-13 | Property page = tabs [Reservations (default) \| Housekeeping] | User direction; rooms overview becomes the Housekeeping tab | Single scrolling page; rooms as collapsible section |
| 2026-06-13 | Keep today's movements as a compact summary strip atop the Reservations tab | User choice; today-at-a-glance stays one glance, list handles the rest | Replace band with quick-filter on the list |
| 2026-06-13 | Reservations tab = reborn property-scoped `ReservationsController#index`; Housekeeping tab = new `RoomsController#index`; `properties#show` redirects to the default (reservations) tab | Symmetric focused read actions, RESTful, each tab linkable; show stays thin. (index was deleted in Property Ops Overview; returns with a richer filterable purpose) | Host both in properties#show |
| 2026-06-13 | List filtering = scopes + `Reservation.filtered` class method on the aggregate root | DDD §6: no query-object PORO until reused from 3 sites; one site here | ReservationFilter query object |
| 2026-06-13 | Booking room re-filter = Turbo Frame GET back into `reservations#new` (room `<select>` in the frame) | No new endpoint; only the room frame reloads so guest selection survives — the actual fix for #2 | Dedicated availability action; full-page reload |
| 2026-06-13 | Guest inline create = Turbo Stream response from `guests#create`; search via `guests#index?q=` | Idiomatic Hotwire, server renders the option, minimal bespoke JS | JSON endpoint + Stimulus-rendered list |
| 2026-06-13 | No Selenium/Capybara system specs; request specs cover server contracts, Turbo/Stimulus verified manually | Browser-driver flakiness in WSL/CI; the JS wiring is thin | Add system spec for booking happy-path |
| 2026-06-13 | Design approved at Level 4. Blueprint complete, ready for implementation | All four levels walked and approved | — |

## Open Questions

<!-- When resolved, capture as decision above and remove from here. -->

## Constraints

<!-- Non-negotiable once recorded. Add only when confirmed. -->

- Builds on merged Properties & Rooms, Guests & Reservations, Property Ops Overview. Guest model has a single `name` column (no separate first/last) — name search matches that field.
- Rails MVC+ (architecture.md): queries as scopes/model methods, preload to avoid N+1, thin controllers, all strings I18n, plain CSS tokens. Stimulus = client sprinkles only, server is source of truth (Turbo Frames/Streams for partial refresh).
- Item #1 (replace the default red placeholder `public/icon.svg`/`icon.png` with an on-brand iris mark) is a trivial fix handled during implementation, not part of this design.

## Design: Level 1 -- Capabilities

Approved 2026-06-13.

1. **Tabbed property page** — two tabs: Reservations (default) and Housekeeping. App home stays the hotel list.
2. **Reservations list** (Reservations tab) — that property's reservations as a list with the today's-movements summary strip pinned on top; filterable by date range, guest, status; searchable by reservation id.
3. **Housekeeping tab** — the room dashboard (state + occupancy) plus room actions (new room, edit, status) moves here.
4. **Unified booking form** — changing dates re-filters available rooms in place without resetting selections; one form (fixes #2).
5. **Guest search + inline create** — guest field becomes a name search bar; no match → create a guest inline and keep booking (fixes #3).

Out of scope: global cross-property reservations view, editing a reservation's dates/room after booking, payments, export, pagination beyond a sensible cap. Icon swap is a trivial implementation fix.

## Design: Level 2 -- Components

Approved 2026-06-13. No new models, schema, or services.

| # | Component | Layer | Responsibility |
|---|-----------|-------|----------------|
| 1 | `Reservation` filter scopes + `.filtered(...)` | Models | `between_dates`, `for_guest`, `with_status` scopes; class method composing them, no-op on blank params |
| 2 | `Guest.search(q)` scope | Models | case-insensitive `name` substring match |
| 3 | `ReservationsController#index` (reborn, property-scoped) | Controllers | Reservations tab: movements strip + filtered/id-searched list |
| 4 | `RoomsController#index` (new, property-scoped) | Controllers | Housekeeping tab: room dashboard + occupancy |
| 5 | `PropertiesController#show` | Controllers | Thin redirect to default tab (`property_reservations_path`) |
| 6 | `ReservationsController#new` | Controllers | Single booking form; room `<select>` in a Turbo Frame re-rendered on date change |
| 7 | `GuestsController#index` (+`q`) & Turbo-Stream `create` | Controllers | Guest search fragment; inline create returns a stream selecting the new guest |
| 8 | Views + Stimulus (`availability`, `guest_search`) | Views/Stimulus | tab shell, reservations index, housekeeping index, unified booking form, two client-only controllers |

```
properties#show ─redirect─▶ reservations#index (Reservations tab: movements strip + Reservation.filtered)
properties/_tabs ─┤
                  rooms#index (Housekeeping tab: rooms + @current_reservations)
reservations#new ─▶ date form ─turbo_frame─▶ available_rooms (room <select>)
                 └▶ guest_search Stimulus ─▶ guests#index?q= ─▶ guests#create (Turbo Stream → select)
```

DDD/architecture: both tabs read through the aggregate root; filters compose scopes on the root (§6); Stimulus client-only; thin controllers. Four judgment calls resolved (see Decisions Log): reborn index, class-method filter, Turbo-Frame room refresh, Turbo-Stream guest create.

## Design: Level 3 -- Interactions

Approved 2026-06-13.

1. **Property page → tabs**: `GET /properties/:id` → `properties#show` → 302 to `property_reservations_path`. Shared `properties/_tabs` partial (header + Reservations/Housekeeping links, active by path) rendered by both tab views.
2. **Reservations tab**: `GET /properties/:id/reservations[?date_from&date_to&guest_id&status&q]` → `reservations#index`. Movements strip always = today (`@arrivals/@departures/@in_house`); list = `@property.reservations.filtered(...)` ordered check_in desc, preloaded guest+room. `q` (reservation id) is a **filter** (narrows list — no reservation show page). Plain GET filter form. Row lifecycle PATCHes redirect to `property_reservations_path`.
3. **Housekeeping tab**: `GET /properties/:id/rooms` → `rooms#index`: `@property.rooms` + `@current_reservations` (checked-in by room). Enhanced dashboard moved here; room writes redirect to `property_rooms_path`.
4. **Booking room re-filter (#2)**: `reservations#new` renders one POST form; room `<select>` inside `turbo_frame_tag "available_rooms"`. Stimulus `availability` sets the frame `src` to `new_property_reservation_path(check_in_on:, check_out_on:)` on date `change`; only that frame reloads → guest selection preserved. No separate "Check availability" button.
5. **Guest search + inline create (#3)**: search input + hidden `reservation[guest_id]` + `guest_results` frame, driven by Stimulus `guest_search`. Search → `GET /guests?q=` into the frame (pick buttons + "Create '<typed>'"). Pick = client-side set hidden + display. Create = POST `guests#create` as turbo_stream → replaces the selection area with "Selected: <name>" + hidden id. `guests#create` keeps HTML redirect for the standalone flow.

Boundary data: controllers extract params → keyword args to `Reservation.filtered`/`Guest.search` (never raw params); Turbo markup assembled in views; Stimulus only debounces/sets fields, server owns availability + renders all options.

## Design: Level 4 -- Contracts

Approved 2026-06-13.

### Routes
Add `:index` to the nested `rooms` and `reservations` resources; `guests#index` honours `?q=`.

### Models
- `Reservation` scopes `between_dates(from,to)` (nil-safe: `check_out_on >= from`, `check_in_on <= to`), `for_guest(guest_id)`, `with_status(status)`; class method `Reservation.filtered(date_from:, date_to:, guest_id:, status:, id:)` composing them, each guarded on `present?`.
- `Guest` scope `search(query)` = `where("name LIKE ?", "%#{query}%")` (bound param).

### Controllers
- `PropertiesController#show` → `redirect_to property_reservations_path(params.expect(:id))`; show view deleted.
- `ReservationsController#index` (+set_property): movements `@arrivals/@departures/@in_house`; `@reservations = @property.reservations.filtered(...params...).includes(:guest,:room).order(check_in_on: :desc)`; `@guests = Guest.order(:name)`. Lifecycle/create redirect → `property_reservations_path`.
- `ReservationsController#new`: drop `@guests`; frame extraction automatic.
- `RoomsController#index` (+set_property): `@current_reservations` (checked-in by room); room writes redirect → `property_rooms_path`.
- `GuestsController#index`: search when `q`; `turbo_frame_request_id == "guest_results"` → render `guests/_picker_results` (layout false) else full index.
- `GuestsController#create`: `respond_to` turbo_stream (select new guest) + html (existing redirect); failure → 422 stream/html.

### Views / frames / streams
`properties/_tabs`; `reservations/index` (+`_reservation_row`); `reservations/new` (one form: `availability` Stimulus on dates, `guests/_picker`, `available_rooms` frame, `reservations/_available_rooms`); `guests/_picker` + `guests/_picker_results` + `guests/create.turbo_stream.erb`; `rooms/index` (moved dashboard). Delete `properties/show.html.erb`.

### Stimulus (`app/javascript/controllers/`)
`availability_controller` (date change → set `available_rooms` frame src, debounced); `guest_search_controller` (debounced search → results frame src; `pick` sets hidden `reservation[guest_id]` + display).

### i18n
Add `properties.tabs.*`; move movement + filter keys to `reservations.index.*`; move room keys to `rooms.index.*`; add `guests.picker.*`; remove unused `properties.show.*`.

### Tests
Model specs (`Reservation.filtered`, `between_dates`, `Guest.search`); request specs (reservations#index filters/id/movements, rooms#index, properties#show redirect, guests#index?q= + frame partial, guests#create turbo_stream, reservations#new frame). No Selenium system specs (avoid CI browser flakiness); Turbo/Stimulus wiring verified manually via run skill.

## Design Summary

**Status: Approved -- ready for implementation** (2026-06-13)

- **Components/layers**: Models — `Reservation` filter scopes + `.filtered`, `Guest.search`. Controllers — reborn `reservations#index`, new `rooms#index`, thin `properties#show` redirect, `guests#index?q=` + turbo_stream `create`, unified `reservations#new`. Views/Stimulus — tab shell, two tab indexes, unified booking form, guest picker, `availability` + `guest_search` controllers. No models/schema/services added.
- **Key contracts**: nested `:index` routes; `Reservation.filtered` keyword signature; `guest_results`/`available_rooms` frame ids; `guests/create.turbo_stream`.
- **Architectural constraints**: queries via scopes/class methods on aggregate roots; thin controllers; Stimulus client-only, server renders all options; Turbo markup in views only; all strings I18n.
- **Domain decisions**: id search is a list filter (no reservation show page); name search on single `name` column; no query-object (DDD §6 rule-of-three unmet).
- **Resolved questions**: "root" = property page tabs; rooms tab = Housekeeping; movements kept as summary strip; four mechanism calls (reborn index, class-method filter, Turbo-Frame room refresh, Turbo-Stream guest create); no system specs.
- **Next step**: `/code-forge` against this blueprint (+ trivial icon swap, item #1).
