---
feature: Reservation Reference Codes
requirement_doc: null
created: "2026-06-14"
---

# Reservation Reference Codes

> Give each reservation a human-friendly code (`internal_id`) instead of exposing the raw integer primary key. 6 uppercase, ambiguity-safe alphanumeric characters, generated on creation, shown in the reservations list and used by the console search. The integer PK, foreign keys, and routes are unchanged.

## Decisions Log

<!-- Add new at bottom. Never remove. -->

| Date | Decision | Reasoning | Alternatives Considered |
|------|----------|-----------|------------------------|
| 2026-06-14 | Add an `internal_id` column; keep the integer PK | Non-invasive: FKs, member routes, and `BookRoom` stay intact; the code is the reservation's own user-facing identity, not derived from a FK | Replace the PK with a string code (rewrites FKs + routes); derive a reversible code from the id (hashids) |
| 2026-06-14 | Column named `internal_id` | User's naming — the reservation's own identifier, distinct from the FKs it holds | `reference`, `code` |
| 2026-06-14 | 6 chars, ambiguity-safe alphabet `ABCDEFGHJKMNPQRSTUVWXYZ23456789` | Short, readable aloud, no look-alikes (I/L/O/0/1 removed); ~888M combinations | 8 chars; prefixed `RSV-…` |
| 2026-06-14 | Generate in a `before_validation, on: :create` callback on the model | Own-data only (architecture §4 allows this); covers every creation path including `BookRoom` and factory-built records. Must be `before_validation`, not `before_create` — validations run before `before_create`, so a `presence` check would fail against the not-yet-assigned code | Generate in `BookRoom` service (misses other paths); `before_create` (validation fires too early) |
| 2026-06-14 | Uniqueness via regenerate-on-collision loop + DB unique index | Random codes collide rarely; the index is the hard guarantee, the loop avoids a failed insert | Sequential-encoded codes; rely on validation only |
| 2026-06-14 | Search is case-insensitive partial match on `internal_id` | Friendlier than exact match when an operator types part of a code; replaces the old exact integer-id filter | Exact match only |
| 2026-06-14 | Code used for display + console search only; routes keep the integer id | No reservation show page exists; member PATCH routes are not user-typed | Use `internal_id` as `to_param` for all routes |
| 2026-06-14 | Blueprint approved, ready for implementation | All four levels walked and approved | — |

## Constraints

- Builds on the merged Guests & Reservations + Reservations Console work. `Reservation` is an aggregate root (ddd §1); `internal_id` is its own attribute.
- Rails MVC+ (architecture.md): generation is a model concern (own data), search is a model scope, controller stays thin, strings are I18n.
- Keep the integer PK, foreign keys, and existing routes unchanged.

## Design: Level 1 -- Capabilities

Approved 2026-06-14.

1. Every reservation gets a unique `internal_id`: 6 uppercase chars from `A–Z` + `2–9` minus look-alikes (`I L O 0 1`), generated automatically on creation.
2. The reservations list shows the `internal_id` instead of the numeric PK.
3. The console `q` search finds a reservation by code — case-insensitive, partial match (`"k7q2"` → `K7Q2X9`).
4. Existing reservations get codes backfilled.

Out of scope: pretty URLs / `to_param`, a reservation show page, changing the PK or FKs.

## Design: Level 2 -- Components

Approved 2026-06-14. No new aggregate, schema table, or service.

| Component | Layer | Responsibility |
|---|---|---|
| `ReservationCode.generate` | Models (PORO) | Pure generator → 6-char ambiguity-safe uppercase string |
| `Reservation` `before_create` + validation | Models | Assign a unique code (retry on collision); `validates :internal_id, presence + uniqueness` |
| `Reservation.with_code` scope; `.filtered(code:)` | Models | Replace the `id:` filter with `internal_id` case-insensitive `LIKE` |
| `ReservationsController#index` | Controllers | Pass `q` as `code:` |
| `reservations/_reservation_row` | Views | Render `internal_id` |
| Migration | DB | Add column, backfill existing rows, unique index, NOT NULL |

`internal_id` is an attribute of the `Reservation` aggregate root; the generator is a domain helper PORO in `app/models`.

## Design: Level 3 -- Interactions

Approved 2026-06-14.

1. **Create:** `Reservations::BookRoom` (unchanged) creates the `Reservation`; its `before_create` callback assigns `internal_id`, regenerating while `Reservation.exists?(internal_id: code)`; the DB unique index is the hard guarantee. Model callback is allowed (own-data only, architecture §4) and also covers factory-built reservations in specs.
2. **Display:** `_reservation_row` renders `reservation.internal_id` in the monospace `.num` cell.
3. **Search:** console `GET …/reservations?q=` → `reservations#index` → `Reservation.filtered(code: params[:q], …)` → `where("internal_id LIKE ?", "%#{q.upcase}%")`, guarded on `present?`.
4. **Backfill:** the migration assigns a unique code to every existing reservation before adding the NOT NULL + unique index.

## Design: Level 4 -- Contracts

Approved 2026-06-14.

### Migration
`add_column :reservations, :internal_id, :string` → backfill each row with `ReservationCode.generate` (uniqueness-checked) → `add_index :reservations, :internal_id, unique: true` → `change_column_null :reservations, :internal_id, false`.

### Models
- `ReservationCode` — `ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"`; `self.generate(length = 6)` → random string from the alphabet.
- `Reservation` — `before_create :assign_internal_id`; `validates :internal_id, presence: true, uniqueness: true`; `assign_internal_id` loops `ReservationCode.generate` until `!Reservation.exists?(internal_id: code)`; `scope :with_code, ->(q) { where("internal_id LIKE ?", "%#{q.upcase}%") }`; `filtered(date_from:, date_to:, status:, code:)` composes `with_code(code) if code.present?` (replaces the `id:` param).

### Controllers
- `ReservationsController#index` passes `code: params[:q]` to `filtered` (was `id: params[:q]`).

### Views / i18n
- `_reservation_row` renders `reservation.internal_id`.
- `reservations.index.search_placeholder` → "Reservation code".

### Tests
- `ReservationCode.generate`: correct length, only allowed characters, varies.
- `Reservation`: assigns an `internal_id` on create; backfill leaves none null.
- `Reservation.filtered(code:)`: case-insensitive partial match.
- Request: console search by code narrows the list; row shows the code.

## Design Summary

**Status: Approved -- ready for implementation** (2026-06-14)

- **Components/layers:** Models — `ReservationCode` generator PORO, `Reservation` `before_create` + `with_code` scope + `filtered(code:)`. Controllers — `reservations#index` passes `code:`. Views — `_reservation_row` shows `internal_id`. DB — add/backfill/index migration. No services or aggregates added.
- **Key contracts:** `ReservationCode.generate`; `internal_id` column (unique, not null); `Reservation.filtered(code:)`.
- **Architectural constraints:** generation is a model concern (own data); search is a model scope; thin controller; strings I18n; PK/FKs/routes unchanged.
- **Domain decisions:** `internal_id` is the Reservation root's own identity; 6-char ambiguity-safe; partial case-insensitive search; display + search only.
- **Next step:** implement via `/code-forge` against this blueprint.
