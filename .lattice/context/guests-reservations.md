---
feature: Guests & Reservations
requirement_doc: null
created: "2026-06-11"
---

# Guests & Reservations

> The booking core of Iris: guest profiles and reservations that link guests to rooms for stay periods — the feature room "availability" has been deliberately reserved for.

## Decisions Log

<!-- Add new at bottom. Never remove. -->

| Date | Decision | Reasoning | Alternatives Considered |
|------|----------|-----------|------------------------|
| 2026-06-11 | Reservation lifecycle via AASM state machine | User direction; explicit legal transitions, AASM::InvalidTransition guards the HTTP boundary | Ad-hoc bang methods; state_machines gem; hand-rolled map |
| 2026-06-11 | Cross-aggregate checkout effect (room → cleaning) in CheckOut service, not AASM callback | Callback side-effects across aggregates are an architecture.md anti-pattern; AASM owns legality, service owns orchestration | after_commit/AASM after callbacks |
| 2026-06-11 | Rate snapshot: reservation copies room.nightly_rate_cents at booking | Historical reservations keep their price when room rates change | Live join to room rate |
| 2026-06-11 | Date columns named check_in_on/check_out_on | AASM events check_in/check_out generate methods that clash with same-named attribute readers | check_in/check_out columns + renamed events |
| 2026-06-11 | AASM owns status column directly; no Rails enum | Double machinery (enum + AASM) causes conflicting methods; AASM provides state scopes | enum + manual guards |
| 2026-06-11 | Cleaning rooms bookable; out_of_service not | Cleaning is transient housekeeping state; out_of_service means unsellable | Blocking both |
| 2026-06-11 | Design approved at Level 4. Blueprint complete, ready for implementation | All four levels walked and approved | — |

## Open Questions

<!-- When resolved, capture as decision above and remove from here. -->

## Constraints

<!-- Non-negotiable once recorded. Add only when confirmed. -->

- Builds on merged Properties & Rooms: `Property` owns `Room`; room status vocabulary (operational/cleaning/out_of_service) is operational state, NOT occupancy — occupancy/availability is derived from reservations (decision logged 2026-06-11 in properties-rooms.md).
- DDD overlay: `Reservation` and `Guest` are aggregate roots referencing `Room`/each other by id; cross-aggregate invariants (no overlapping reservations) live in a verb-named service inside a transaction.
- Multi-aggregate writes require a service object owning the transaction (architecture.md); enum params guarded at every HTTP boundary (operational learning).
- All user-facing strings via I18n; RSpec + FactoryBot; single line ≤70 char commits.

## Design: Level 1 -- Capabilities

Approved 2026-06-11.

1. **Manage guest profiles** — create, edit, view guests (name, email, phone); stay history on guest page.
2. **Book a room** — reservation for guest: room + check-in/check-out, nightly rate captured at booking; double-bookings refused (overlap on same room).
3. **Walk the stay lifecycle** — `booked → checked_in → checked_out`, or `cancelled` before check-in; checkout flips room to *cleaning* (first cross-aggregate effect).
4. **See the house** — per property: today's arrivals, departures, in-house; current occupancy on the room board.
5. **Check availability** — rooms free in a property for a date range.

Out of scope: payments/invoices/folios, rate plans/seasonal pricing, group bookings, OTA/channel sync, no-show automation, overbooking rules.

Status vocabulary asserts facts: `booked`, `checked_in`, `checked_out`, `cancelled`.

## Design: Level 2 -- Components

Approved 2026-06-11.

| # | Component | Layer | Responsibility |
|---|-----------|-------|----------------|
| 1 | `Guest` | Models | Aggregate root: identity + contact details |
| 2 | `Reservation` | Models | Aggregate root: guest + room by id; stay dates, rate snapshot, lifecycle, house-view scopes |
| 3 | `StayPeriod` | Models | Value object (`Data.define`): check_in/check_out, validity, `nights`, `overlaps?` |
| 4 | `Room` availability scopes | Models | `available_between(period)`, current-occupancy query (extends existing Room) |
| 5 | `Reservations::BookRoom` | Services | Transaction: overlap check + create; raises `Reservations::RoomUnavailableError` |
| 6 | `Reservations::CheckOut` | Services | Transaction: reservation → `checked_out`, room → `cleaning` (cross-aggregate) |
| 7 | `GuestsController` + views | Controllers/Views | Guest CRUD + stay history |
| 8 | `ReservationsController` + views | Controllers/Views | Property-scoped house view + booking; lifecycle actions |

```
GuestsController ───────▶ Guest ◀──────────────┐ guest_id
ReservationsController ─▶ Reservations::BookRoom ──▶ Reservation ─┐ room_id
                   └────▶ Reservations::CheckOut ──▶ Reservation + Room
Property show / room board ──▶ Room scopes ◀── Reservation scopes
StayPeriod (VO) used by Reservation + Room.available_between
```

DDD: two new aggregate roots (`Guest`, `Reservation`), one VO (`StayPeriod`); cross-aggregate refs by id; no domain events — CheckOut service orchestrates explicitly. Check-in/cancel are model methods (single-aggregate; service would be anemic).

## Design: Level 3 -- Interactions

Approved 2026-06-11 (revised once: AASM state machine for lifecycle).

**Flow 1 — Book a room**: GET reservations/new builds StayPeriod from optional date params → `property.rooms.available_between(stay_period)` + guest list. POST → controller extracts values → `Reservations::BookRoom.call(room:, guest:, stay_period:)` → one transaction: overlap check (booked/checked_in reservations on that room) raising `Reservations::RoomUnavailableError`, then `create!` with rate snapshot from `room.nightly_rate_cents`. Success → house view; domain error/validation → 422 re-render.

**Flow 2 — Lifecycle (AASM)**: states booked (initial) / checked_in / checked_out / cancelled; events `check_in` (booked→checked_in), `check_out` (checked_in→checked_out), `cancel` (booked→cancelled). PATCH member routes call `reservation.check_in!` / `Reservations::CheckOut.call` (transaction: AASM check_out! + `room.change_status!("cleaning")`) / `reservation.cancel!`. `AASM::InvalidTransition` rescued in controller → redirect + flash alert. Cross-aggregate effect lives in the service, never in AASM callbacks.

**Flow 3 — House view**: GET /properties/:id/reservations → three preloaded groups (guest+room): arrivals today (booked, check_in=today), departures today (checked_in, check_out=today), in-house (checked_in).

**Flow 4 — Room board occupancy**: properties#show preloads each room's current checked_in reservation; occupied rooms show guest name.

Boundary data: primitives/StayPeriod into services; services return reservation or raise domain errors; one transaction per service. SQLite single-writer makes the overlap check race-safe locally.

## Design: Level 4 -- Contracts

Approved 2026-06-11.

### Schema

```ruby
create_table :guests do |t|
  t.string :name, null: false
  t.string :email
  t.string :phone
  t.timestamps
  t.index :email, unique: true, where: "email IS NOT NULL"
end

create_table :reservations do |t|
  t.references :guest, null: false, foreign_key: true
  t.references :room, null: false, foreign_key: true
  t.date    :check_in_on, null: false
  t.date    :check_out_on, null: false
  t.integer :nightly_rate_cents, null: false
  t.string  :status, null: false, default: "booked"
  t.timestamps
  t.index [ :room_id, :check_in_on ]
  t.index :status
end
```

### Models

- `StayPeriod = Data.define(:check_in, :check_out)` with `valid?`, `nights`, `overlaps?(other)` (half-open: back-to-back stays don't overlap).
- `Guest`: `has_many :reservations` (desc by check_in_on); name presence; email uniqueness allow_blank.
- `Reservation`: `include AASM` (column :status — no Rails enum): states booked (initial)/checked_in/checked_out/cancelled; events check_in (booked→checked_in), check_out (checked_in→checked_out), cancel (booked→cancelled). Scopes: `overlapping(period)` (booked+checked_in, `check_in_on < ? AND ? < check_out_on`), `arriving_on(date)`, `departing_on(date)`. Methods: `stay_period`, `total_cents`. Validations: dates present, check_out_on > check_in_on, rate >= 0.
- `Room` additions: `has_many :reservations`; `available_between(period)` = not out_of_service, no overlapping reservation; `current_reservation` = checked_in first.

### Services

- `Reservations::RoomUnavailableError < StandardError`
- `Reservations::BookRoom.new(room:, guest:, stay_period:).call` → Reservation; one transaction; raises RoomUnavailableError (out_of_service or overlap) or RecordInvalid; rate snapshot from room.
- `Reservations::CheckOut.new(reservation:).call` → one transaction: AASM check_out! + room.change_status!("cleaning").

### Routes

```ruby
resources :guests, only: %i[ index show new create edit update ]
resources :properties (existing) do
  resources :reservations, only: %i[ index new create ], shallow: true do
    member { patch :check_in; patch :check_out; patch :cancel }
  end
end
```

### Failure modes & specs

- RoomUnavailableError/validation → 422 re-render; AASM::InvalidTransition → redirect + flash alert.
- Factories :guest, :reservation (traits :checked_in/:checked_out/:cancelled); StayPeriod unit specs; model specs (transitions, overlap edges); service specs (conflict, out_of_service, checkout flips room to cleaning); request specs incl. illegal transition.

## Design Summary

**Status: Approved -- ready for implementation** (2026-06-11)

- **Components/layers**: `Guest`, `Reservation` (AASM), `StayPeriod` VO, Room scope additions (Models); `Reservations::BookRoom`, `Reservations::CheckOut` (Services); `GuestsController`, `ReservationsController` + views (Controllers/Views).
- **Key contracts**: schema above; AASM events as the only lifecycle mutators; services own transactions and cross-aggregate effects; shallow reservation routes with three PATCH member actions.
- **Architectural constraints**: no AASM callbacks for cross-aggregate effects; controllers pass primitives/StayPeriod; enum/state params guarded at HTTP boundary; availability derived, never stored.
- **Domain decisions**: rate snapshot at booking; `_on` suffix for date columns (AASM clash); cleaning bookable, out_of_service not; half-open date overlap.
- **Resolved questions**: lifecycle = AASM state machine (user direction).
- **Next step**: `/code-forge` against this blueprint (new gem: aasm).

## Key Files

<!-- Add as dev progresses. List paths with brief role note. -->

Implemented 2026-06-13 (`/code-forge`):

- `app/models/stay_period.rb` — `Data.define` VO; half-open `overlaps?`, `nights`, `valid?`.
- `app/models/guest.rb` — aggregate root; `has_many :reservations` (desc check_in_on).
- `app/models/reservation.rb` — AASM on `:status`; `overlapping`/`arriving_on`/`departing_on` scopes; `stay_period`, `total_cents`.
- `app/models/room.rb` — added `has_many :reservations`, `available_between` scope, `current_reservation`.
- `app/models/property.rb` — added `has_many :reservations, through: :rooms` for the house view.
- `app/services/reservations/{room_unavailable_error,book_room,check_out}.rb` — booking + checkout transactions.
- `app/controllers/{guests,reservations}_controller.rb` — CRUD + house view/booking/lifecycle; `rescue_from AASM::InvalidTransition`.
- `app/views/guests/*`, `app/views/reservations/*`, room board occupancy column, `reservation_status_tag`/`room_option_label` helpers.
- `db/migrate/20260613120000_create_guests.rb`, `db/migrate/20260613120001_create_reservations.rb`.
- Specs: `spec/models/{stay_period,guest,reservation,room}_spec.rb`, `spec/services/reservations/*`, `spec/requests/{guests,reservations}_spec.rb`. Full suite green (82 examples).
