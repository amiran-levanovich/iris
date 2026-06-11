---
feature: Properties & Rooms
requirement_doc: null
created: "2026-06-11"
---

# Properties & Rooms

> Core inventory of Iris: staff manage hotels (properties) and the rooms inside them — the foundation reservations and maintenance requests will hang off.

## Decisions Log

<!-- Add new at bottom. Never remove. -->

| Date | Decision | Reasoning | Alternatives Considered |
|------|----------|-----------|------------------------|
| 2026-06-11 | Auth is a separate prerequisite feature, not part of Properties & Rooms | Keeps this blueprint focused on inventory; Rails 8 auth generator is a small standalone step done right before implementation | Including sign-in as capability 5 |
| 2026-06-11 | Rooms are never hard-deleted; out-of-service status instead | Future reservations/maintenance reference rooms; history must survive | Hard delete with dependent: destroy |
| 2026-06-11 | Room status named `operational`, not `available` | "available" will mean "no reservation tonight" once reservations exist; avoid vocabulary collision | available/unavailable |
| 2026-06-11 | Three statuses: operational/cleaning/out_of_service; single PATCH status action | Housekeeping state is realistic hotel ops; 3 named routes would be clutter, enum rejects unknown values | 2 statuses; named route per transition; occupancy as status (rejected: derivable from reservations) |
| 2026-06-11 | Nightly rate stays integer cents | Safer money convention; value object deferred until arithmetic appears | decimal(8,2) |
| 2026-06-11 | Shallow nesting for rooms | edit/update/status don't need property in URL; create does | Full nesting |
| 2026-06-11 | No service objects in this feature | Every write is single-aggregate; services would be anemic per architecture.md anti-patterns | Service per use case |
| 2026-06-11 | Design approved at Level 4. Blueprint complete, ready for implementation | All four levels walked and approved | — |

## Open Questions

<!-- When resolved, capture as decision above and remove from here. -->

## Design: Level 1 -- Capabilities

Approved 2026-06-11.

1. **Manage properties** — create, edit, and view hotels with basic details (name, address).
2. **Manage rooms within a property** — add and edit rooms: room number, type, capacity, nightly rate.
3. **See the inventory at a glance** — a property page lists its rooms with operational status.
4. **Take rooms in/out of service** — rooms can be marked out of service and restored; never hard-deleted.

Out of scope: occupancy/availability (derived from reservations later), photos, seasonal pricing, multi-currency, staff sign-in (separate feature).

## Design: Level 2 -- Components

Approved 2026-06-11.

| # | Component | Layer | Responsibility |
|---|-----------|-------|----------------|
| 1 | `Property` | Models | Aggregate root: hotel details (name, address); owns rooms; validations |
| 2 | `Room` | Models | Child entity: number (unique per property), type, capacity, nightly rate, operational status + transitions |
| 3 | `PropertiesController` | Controllers | CRUD for properties |
| 4 | `RoomsController` | Controllers | Room CRUD + in/out-of-service action, always scoped through a property |
| 5 | Property/Room views | Views | Property list & detail (rooms table with status), forms |

```
Views (index/show/forms)
        │ renders
PropertiesController ──▶ Property ◀─┐ has_many / owns
RoomsController ───────▶ Room ──────┘ (always accessed via property.rooms)
```

DDD: `Property` = aggregate root; `Room` = entity inside the Property aggregate (no bare `Room.create` — always via `property.rooms`). No value objects yet (rate stays integer cents until behavior appears). No services — single-aggregate CRUD only (anemic-service anti-pattern). No jobs/mailers/custom Stimulus.

## Design: Level 3 -- Interactions

Approved 2026-06-11.

**Flow 1 — Add a room (write)**: POST /properties/:property_id/rooms → RoomsController#create loads Property, extracts values via params.expect, builds through `property.rooms`; Room validates (number unique within property, capacity > 0, rate >= 0); success → redirect to property page; failure → re-render form with errors.

**Flow 2 — Toggle service status (write)**: PATCH → RoomsController → `property.rooms.find(:id)` → status transition on Room → redirect back to property page.

**Flow 3 — View inventory (read)**: GET /properties/:id → PropertiesController#show → Property with rooms preloaded ordered by number → view renders details + rooms table.

Boundary data: controllers pass extracted primitives into models; views receive AR objects. No transactions (single-record writes only). Plain redirects, no Turbo Streams in v1.

## Design: Level 4 -- Contracts

Approved 2026-06-11 (after one revision round).

### Schema

```ruby
create_table :properties do |t|
  t.string  :name, null: false
  t.string  :street
  t.string  :city
  t.string  :postal_code
  t.string  :country
  t.text    :description
  t.integer :stars                     # 1..5, optional
  t.timestamps
end

create_table :rooms do |t|
  t.references :property, null: false, foreign_key: true
  t.string  :number, null: false
  t.string  :room_type, null: false
  t.integer :capacity, null: false
  t.integer :nightly_rate_cents, null: false, default: 0
  t.string  :status, null: false, default: "operational"
  t.integer :floor
  t.text    :description
  t.timestamps
  t.index [:property_id, :number], unique: true
end
```

### Models

```ruby
class Property < ApplicationRecord
  has_many :rooms, -> { order(:number) }, dependent: :restrict_with_error
  validates :name, presence: true
  validates :stars, numericality: { only_integer: true, in: 1..5 }, allow_nil: true
end

class Room < ApplicationRecord
  belongs_to :property
  enum :room_type, { single: "single", double: "double", twin: "twin", suite: "suite",
                     family: "family", deluxe: "deluxe", penthouse: "penthouse" }
  enum :status,    { operational: "operational", cleaning: "cleaning",
                     out_of_service: "out_of_service" }
  validates :number, presence: true, uniqueness: { scope: :property_id }
  validates :capacity, numericality: { only_integer: true, greater_than: 0 }
  validates :nightly_rate_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :floor, numericality: { only_integer: true }, allow_nil: true

  def change_status!(new_status)  # enum raises ArgumentError on unknown value
end
```

### Routes

```ruby
resources :properties, only: %i[index show new create edit update] do
  resources :rooms, only: %i[new create edit update], shallow: true do
    member { patch :status }   # params: { status: "cleaning" } → room.change_status!
  end
end
```

### Failure modes & specs

- `RecordNotFound` → 404; validation failure → re-render with `status: :unprocessable_entity`; unknown status value → ArgumentError (controller maps to 422 or 400).
- Factories `:property`, `:room` (traits `:cleaning`, `:out_of_service`); model specs for validations/`change_status!`; request specs per controller action.

## Design Summary

**Status: Approved -- ready for implementation** (2026-06-11)

- **Components/layers**: `Property` + `Room` (Models, one aggregate: Property owns Rooms), `PropertiesController` + `RoomsController` (Controllers, thin CRUD), ERB views with rooms table. No services, jobs, mailers, or custom Stimulus.
- **Key contracts**: schema + model interfaces + shallow nested routes above; single `PATCH status` member action; `change_status!` model command.
- **Architectural constraints**: rooms only via `property.rooms`; no destroy actions; no raw `params` past controllers; no transactions needed.
- **Domain decisions**: status vocabulary `operational/cleaning/out_of_service` (not "available" — reserved for reservation-derived availability); rate as integer cents; value objects deferred.
- **Resolved questions**: auth = separate prerequisite feature (Rails 8 generator) before implementation.
- **Next step**: `/code-forge` against this blueprint.

## Constraints

<!-- Non-negotiable once recorded. Add only when confirmed. -->

- Rails MVC+ architecture per `.lattice/standards/architecture.md` (thin controllers, domain rules in models, services only for multi-model workflows).
- DDD overlay: `Property` is the aggregate root that owns `Room`; rooms are created/archived only through their property.
- RSpec + FactoryBot; no fixtures.

## Key Files

<!-- Add as dev progresses. List paths with brief role note. -->
