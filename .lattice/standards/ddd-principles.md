---
mode: overlay
---

> This document contains Iris-specific DDD sections that replace the corresponding sections of the domain-driven-design atom's embedded defaults. Sections not listed here use the defaults. Context: Rails 8.1 + ActiveRecord — tactical DDD is applied pragmatically inside Rails conventions, not via a separate domain layer.

**Included sections:**

1. [Aggregate Design Rules](#1-aggregate-design-rules)
3. [Value Object Patterns](#3-value-object-patterns)
5. [Domain Event Patterns](#5-domain-event-patterns)
6. [Repository Patterns](#6-repository-patterns)

---

## 1. Aggregate Design Rules

An aggregate is an ActiveRecord root plus the child records it exclusively owns, enforced through associations, validations, and `dependent:` options — not through a separate aggregate class.

**Iris aggregate roots:**

| Root | Owns | Notes |
|------|------|-------|
| `Property` | `Room` | Rooms are created/archived only through their property |
| `Guest` | — | Profile + contact details |
| `Reservation` | — | References `Room` and `Guest` by id; owns its own lifecycle (status transitions) |
| `MaintenanceRequest` | — | References `Room` by id |

**Rules:**

- Cross-aggregate references are by id (`belongs_to`), never by reaching through another root to mutate its children (`reservation.room.property.update!` is a violation).
- Invariants that span one aggregate live in that model's validations; invariants that span aggregates (e.g., "room has no overlapping reservations") live in the service that owns the use case, inside a transaction.
- One root per transaction is the norm; multi-root writes happen only inside a verb-named service object.
- Keep aggregates small: if a root accumulates children with independent lifecycles, split (see §8 Decomposition Guide).

## 3. Value Object Patterns

Value objects are immutable `Data.define` POROs in `app/models`, used to kill primitive obsession at domain hot-spots:

- `StayPeriod` — `check_in`/`check_out` dates with validity (`check_out > check_in`), `nights`, and `overlaps?(other)` logic. Reservations expose `reservation.stay_period`, not raw date pairs.
- Money is stored as integer cents in the DB and wrapped in a value object when arithmetic or formatting beyond display appears (don't pre-build it).
- Equality is by value (`Data.define` gives this for free); no identity, no persistence of their own.
- Mapping to AR: plain mapper methods on the model (or `composed_of`); columns stay primitive, behavior lives on the value object.
- Don't wrap every column — a value object earns its existence by carrying behavior (validation, comparison, arithmetic), not by renaming a string.

## 5. Domain Event Patterns

Domain events are **not used in v1**. Cross-aggregate effects are orchestrated explicitly:

- The service object that owns the use case performs follow-up effects synchronously, or enqueues a Solid Queue job for async work (mail, notifications).
- No event bus, no `Wisper`-style pub/sub, no AR callbacks as an implicit event mechanism for cross-aggregate effects.
- If a future feature genuinely needs decoupled subscribers, revisit this section first — introducing events is a standards change, not a local decision.

## 6. Repository Patterns

There is no repository layer. ActiveRecord **is** the persistence API:

- Query access goes through named scopes and class methods on the aggregate root (`Reservation.overlapping(stay_period)`, `Room.available_between(...)`).
- Child records are accessed through their root (`property.rooms`), not queried bare from unrelated code.
- No generic query objects until a query is reused from three call sites with variations; then extract a PORO in `app/models`.
- Specs use FactoryBot + the real database (SQLite, transactional); no in-memory repository fakes.

---

*Generated for Iris on 2026-06-11. Mode: overlay.*
*Produced by the ddd-refiner skill.*
