---
feature: Reservation Detail & Management
requirement_doc: null
created: "2026-06-15"
---

# Reservation Detail & Management

> A reservation gets a real show page: a row in the reservations console now links through to full reservation info, guest data, room information, and a unified activity log. From there staff can reschedule (dates), move the room, adjust the nightly rate, and add comments — all recorded, with edit permissions tiered by lifecycle state. This reverses the Reservations Console decision that id-search was a filter with "no reservation show page".

## Decisions Log

<!-- Add new at bottom. Never remove. -->

| Date | Decision | Reasoning | Alternatives Considered |
|------|----------|-----------|------------------------|
| 2026-06-15 | Introduce a reservation show page (`reservations#show`) | This feature's premise; reverses the Reservations Console call that id-search was a list filter with no show page | Keep id-search as filter only |
| 2026-06-15 | "Timeline" = one **unified, persisted activity log** (lifecycle transitions + edits + comments), authored by the acting staff user | User choice; gives a real audit trail and a natural home for comments | Derived lifecycle-only timeline + separate comments list |
| 2026-06-15 | Edit policy **tiered by lifecycle state**: booked → dates/room/rate; checked_in → rate + check-out date only (room & check-in locked); checked_out/cancelled → read-only | User choice; mirrors real PMS constraints (in-house guest can't change room/arrival) | Booked-only editable; any non-cancelled fully editable |
| 2026-06-15 | Comments are **append-only**, authored (user + body + timestamp), no edit/delete; rendered inside the activity log | User choice; honest record, fits the audit intent | Editable/deletable by author |
| 2026-06-15 | Level 1 approved; deferred items captured in a standing `context/backlog.md` planned-features list (aggregated across all design sessions) | User direction ("make a list of planned features, all of them should be in the list") | Leave out-of-scope items only inside each context doc |
| 2026-06-15 | Activity log is a **child of the `Reservation` aggregate** (`has_many :activities, dependent: :destroy`) — Iris's first aggregate child; references `User` author by id | DDD overlay §1 (root + exclusively-owned children via association + `dependent:`); audit entries have no life outside their reservation | Standalone audit aggregate; polymorphic `Comment`/`Activity` across models |
| 2026-06-15 | One `ReservationActivity` model, kinds `comment`/`transition`/`edit`; structured `details` JSON rendered via I18n (never store rendered English) | Single feed = single table; structured payload keeps the no-hardcoded-strings rule and lets the view localize | Separate `Comment` + `AuditEvent` tables; storing pre-rendered sentences |
| 2026-06-15 | `check_in`/`cancel` stay **model methods** (single-aggregate transition + activity append); `check_out` stays a **service** (cross-aggregate room effect); edits go through one `Reservations::ReviseReservation` service | architecture.md §8 default (model owns state change; service owns cross-aggregate orchestration); avoids anemic per-field services; activity construction centralized on the root (`log_transition`) | Promote all lifecycle to services for symmetry; per-field edit services (Reschedule/ChangeRoom/ChangeRate) |
| 2026-06-15 | `Room.available_between` extended with `except:` a reservation so a stay doesn't conflict with its own current hold on reschedule/room-change | Reuse the read-side scope as the write guard (operational learning); self-overlap is the one difference from booking | Separate "available for edit" scope; inline `where.not(id:)` in the service |
| 2026-06-15 | Edit lives on a **separate edit page** (`GET edit` → `PATCH update` → redirect to show), not inline Turbo on show | Matches the app's existing guests/rooms/properties edit idiom (plain redirects); reuses the booking form's `available_rooms` Turbo frame for date→room re-filter | Inline Turbo-frame editing on the show page |
| 2026-06-15 | All actions (lifecycle, edit, comment) live on the **show page only**; console row code becomes a plain link, row lifecycle buttons removed; lifecycle PATCH actions now **redirect to show** (was `property_reservations_path`) | One home for actions; declutters console; every action redirects to show → no origin-based redirect, sidestepping the open-redirect bug class from a prior review | Keep quick-action buttons on the console row + show (needs guarded `return_to`) |
| 2026-06-15 | Comments via a nested `Reservations::CommentsController#create` (route `scope module: :reservations`), not a member action on `ReservationsController` | Keeps `ReservationsController` focused; mirrors the `Reservations::` service namespace; REST-clean single-action controller | `post :comment` member action on the already-broad ReservationsController |
| 2026-06-15 | `ReviseReservation` reuses the booking guards — `PastDateError` (check-in moved to past) and `RoomUnavailableError` (`available_between(except: self)`) | One policy for "valid stay + free room", whether booking or rescheduling; reuses existing errors/locale | Reschedule-specific errors and date rules |
| 2026-06-15 | Design approved at Level 4. Blueprint complete, ready for implementation | All four levels walked and approved | — |

## Open Questions

<!-- When resolved, capture as decision above and remove from here. -->

- (Level 2) Service decomposition for the write paths (single `ModifyReservation` vs per-operation services) and how lifecycle transitions record their activity entry atomically with an author — resolve as a judgment call at Level 2.
- Activity author display: `User` has only `email_address` (no name column) — show email, or add a display name? Default: email for now.

## Constraints

<!-- Non-negotiable once recorded. Add only when confirmed. -->

- Builds on merged Guests & Reservations + Reservations Console. `Reservation` is an aggregate root referencing `Room`/`Guest` by id; `StayPeriod` VO carries date logic; AASM owns the `status` lifecycle; rate is a snapshot (`nightly_rate_cents`).
- Rails MVC+ (architecture.md): thin controllers; multi-model/cross-aggregate writes go through a verb-named service owning the transaction; queries via scopes/model methods on the aggregate root; no AASM callbacks for cross-aggregate effects; Stimulus client-only.
- DDD overlay: the activity log is a **child of the `Reservation` aggregate** (exclusively owned, `dependent: :destroy`, accessed through the root) — Iris's first aggregate child. Cross-aggregate refs by id. No domain events in v1 (effects orchestrated explicitly in services).
- Models must not reference `Current`/request state — the acting user (activity author) is passed from the controller into the service/model as `actor:`.
- Availability re-checks on reschedule/room-change must reuse `Room.available_between` and exclude the reservation itself (don't conflict with one's own current hold).
- All user-facing strings via I18n (activity entries stored structured, rendered through I18n — never store pre-rendered English). RSpec + FactoryBot. Edit/enum/FK inputs guarded at the HTTP boundary (operational learnings).

## Design: Level 1 -- Capabilities

Approved 2026-06-15.

1. **View a reservation** — a console row links to a show page presenting full reservation info (code, status, dates, nights, nightly rate, total), the guest's data, and the room's information.
2. **Reschedule the stay** — change check-in/check-out dates; availability is re-checked for the room (excluding this reservation); conflicts are refused. Allowed per the tiered policy (booked: both dates; checked_in: check-out only).
3. **Move to another room** — reassign the reservation to a different available room for its dates; availability re-checked. Allowed while booked only.
4. **Adjust the nightly rate** — change the rate snapshot for this reservation. Allowed while booked or checked_in.
5. **Add comments** — append-only staff notes (author + body + timestamp) on the reservation.
6. **See the activity log** — one unified, chronological feed of lifecycle transitions, edits (dates/room/rate), and comments, each with author and time.
7. **Drive the lifecycle from the show page** — check-in / check-out / cancel actions available inline (subject to AASM legality), each recorded in the activity log.

Out of scope: payments/folios, rate plans/seasonal pricing, partial-night or hourly stays, splitting/merging reservations, editing guest identity from here (guest has its own pages), notifications/emails on changes, cross-property moves, undo/restore of cancelled reservations.

## Design: Level 2 -- Components

Approved 2026-06-15. One new model (aggregate child), one new service, one new error; the rest extend existing classes.

| # | Component | Layer | Responsibility |
|---|-----------|-------|----------------|
| 1 | `ReservationActivity` (new) | Models | Aggregate child of `Reservation`: append-only feed entry — `kind` (comment/transition/edit), optional `body`, structured `details` JSON, `user` author, `created_at`. Scope `chronological`. |
| 2 | `Reservation` (extend) | Models | `has_many :activities, dependent: :destroy`; tiered predicates `check_in_editable?`/`check_out_editable?`/`room_editable?`/`rate_editable?`/`editable?`; entry constructors `log_transition(event, by:)`/`log_edit(changes, by:)`/`add_comment(body, by:)`; lifecycle wrappers `check_in_by!(actor)`/`cancel_by!(actor)` (transition + log in a txn). |
| 3 | `Reservations::ReviseReservation` (new) | Services | Edit use case (dates/room/rate together): tiered-policy guard, availability re-check excluding self, transactional apply, one `edit` diff entry. Raises `EditNotAllowedError`/`RoomUnavailableError`/`RecordInvalid`. |
| 4 | `Reservations::CheckOut` (extend) | Services | Existing checkout (room→cleaning, maintenance-guarded) + `log_transition` with actor in its txn. |
| 5 | `Reservations::EditNotAllowedError` (new) | Services | Raised when an edit touches a field locked by the current lifecycle state (HTTP-boundary guard). |
| 6 | `Room.available_between` (extend) | Models | Accept `except:` a reservation so it doesn't conflict with its own current hold. |
| 7 | `ReservationsController` (extend) | Controllers | New `show`; `edit`/`update` → ReviseReservation; comment create → `add_comment`; lifecycle from show. Thin; `actor = Current.user`; guard edit/FK inputs → 422. |
| 8 | Views + Stimulus | Views/Stimulus | `reservations/show` (summary, guest/room panels, tiered edit form, activity feed `_activity`, comment form); console row code → show link; reuse `availability` Stimulus + `available_rooms` frame for the edit form's date→room re-filter. |

```
console row ──link──▶ reservations#show ──▶ Reservation (+ guest, room, activities)
reservations#update ─▶ Reservations::ReviseReservation ─▶ Reservation (dates/room/rate)
                          ├─ Room.available_between(except: self)   [spanning invariant]
                          └─ reservation.log_edit(diff, by: actor)
#comments ──────────▶ reservation.add_comment(body, by: actor)
check_in / cancel ──▶ reservation.check_in_by!/cancel_by!(actor)  → transition + log
check_out ──────────▶ Reservations::CheckOut(actor:)             → checkout + room→cleaning + log
                                   ▼
                          ReservationActivity (child) ──by──▶ User
```

Validation: first aggregate child (owned, `dependent: :destroy`, reached only via `reservation.activities`); `User` referenced by id; spanning invariant in the service inside a txn reusing `available_between`; intentional model-vs-service asymmetry per architecture.md §8; no AASM callbacks for logging; actor passed in, no `Current` in models; thin controllers.

## Design: Level 3 -- Interactions

Approved 2026-06-15. Edit = separate page; all actions on the show page only.

1. **Show** — `GET /reservations/:id` → `reservations#show`; preload `includes(:guest, room: :property, activities: :user)` (no N+1). Renders summary (code, status pill, dates, nights, rate, total), guest panel, room panel, "Edit reservation" link, activity feed (chronological `_activity` partial localized per `kind`), comment form, lifecycle buttons gated by `may_*?`.
2. **Edit** — `GET /reservations/:id/edit` renders a form exposing only fields allowed by the tiered predicates (locked fields read-only). Room `<select>` in the reused `available_rooms` Turbo frame + `availability` Stimulus, `src` carrying `except` = this reservation. `PATCH /reservations/:id` → controller extracts primitives → `Reservations::ReviseReservation.call(reservation:, actor: Current.user, check_in_on:, check_out_on:, room_id:, nightly_rate_cents:)`. Success → redirect to show + notice; `EditNotAllowedError`/`RoomUnavailableError` → re-render edit 422 + alert; `RecordInvalid` → re-render edit 422 + field errors.
3. **Comment** — `POST /reservations/:id/comments` → `reservation.add_comment(body, by: Current.user)` → redirect to show (blank body → 422 + alert). Allowed in any state.
4. **Lifecycle from show** — `check_in` → `reservation.check_in_by!(actor)`; `cancel` → `reservation.cancel_by!(actor)`; `check_out` → `Reservations::CheckOut.call(reservation:, actor:)`; each logs a `transition` entry; all three redirect to show; `AASM::InvalidTransition` → redirect + alert (existing rescue).
5. **Console row → show** — `_reservation_row` code cell becomes `link_to reservation.internal_id, reservation_path(reservation)`; row lifecycle buttons removed (now live on show).

Boundary data: controller extracts values → keyword args into `ReviseReservation` (never raw `params`); `actor` passed explicitly; Turbo markup in views only; Stimulus only sets the frame `src`.

## Design: Level 4 -- Contracts

Approved 2026-06-15.

### Schema (new migration)

```ruby
create_table :reservation_activities do |t|
  t.references :reservation, null: false, foreign_key: true
  t.references :user, foreign_key: true            # author; nullable (system/seed)
  t.string  :kind,    null: false                  # comment | transition | edit
  t.text    :body                                   # comments only
  t.json    :details, null: false, default: {}      # transition: {event}; edit: {changes:{field:[from,to]}}
  t.datetime :created_at, null: false               # append-only: created_at only, no updated_at
end
add_index :reservation_activities, [ :reservation_id, :created_at ]
```

### Models

- `ReservationActivity` (new): `belongs_to :reservation`; `belongs_to :user, optional: true`; `validates :kind, inclusion: %w[comment transition edit]`; `validates :body, presence: true, if: comment?`; `scope :chronological, -> { order(:created_at) }`; immutable — `def readonly? = persisted?`.
- `Reservation` (extend): `has_many :activities, -> { chronological }, class_name: "ReservationActivity", dependent: :destroy`.
  - Predicates: `check_in_editable? = booked?`; `room_editable? = booked?`; `check_out_editable? = booked? || checked_in?`; `rate_editable? = booked? || checked_in?`; `editable? = booked? || checked_in?`.
  - Constructors: `log_transition(event, by:)`, `log_edit(changes, by:)`, `add_comment(body, by:)` (single-aggregate appends).
  - Wrappers: `check_in_by!(actor)` / `cancel_by!(actor)` → `transaction { check_in!/cancel!; log_transition(..., by: actor) }`.
- `Room.available_between` (extend): `->(period, except: nil)` — conditionally `where.not(id: except.id)` on the overlapping subquery.

### Services

- `Reservations::ReviseReservation.new(reservation:, actor:, check_in_on:, check_out_on:, room_id:, nightly_rate_cents:).call`: diff vs current (empty → no-op return); tiered guard → `EditNotAllowedError`; check-in moved to past → `PastDateError` (reused); dates/room changed → require `Room.available_between(period, except: reservation)` else `RoomUnavailableError` (reused); `transaction { assign + save!; log_edit(diff, by: actor) }`. Diff stores dates as ISO strings, rate as cents, room as number string.
- `Reservations::CheckOut` (extend): add `actor:`; `log_transition(:check_out, by: actor)` in the txn.
- `Reservations::EditNotAllowedError < StandardError` (new).

### Routes

```ruby
resources :reservations, only: %i[ index new create show edit update ], shallow: true do
  member { patch :check_in; patch :check_out; patch :cancel }
  scope module: :reservations do
    resources :comments, only: :create        # Reservations::CommentsController
  end
end
```

### Controllers

- `ReservationsController`: add `show` (preload `includes(:guest, room: :property, activities: :user)`), `edit`, `update`. `update` → `ReviseReservation.call(... actor: Current.user)`; rescues `EditNotAllowedError`→422 `.not_allowed`, `RoomUnavailableError`→422 `.unavailable`, `PastDateError`→422 `.past_date`, `RecordInvalid`→422 field errors. Lifecycle actions redirect to `reservation_path`; `check_out` passes `actor:`.
- `Reservations::CommentsController#create`: `params.expect(comment: [:body])` → `@reservation.add_comment(body, by: Current.user)` → redirect to `reservation_path`; blank → 422 + alert.

### Views / Stimulus

`reservations/show`, `reservations/edit`, `reservations/_activity` (localized per `kind`); reuse `reservations/_available_rooms` frame + `availability` Stimulus (edit form passes `except` = reservation id into the frame `src`); update `_reservation_row` (code → `link_to reservation_path`, remove row buttons).

### i18n

`reservations.show.*`, `reservations.edit.*`, `reservations.update.{notice,not_allowed,unavailable,past_date}`, `reservations.comment.{notice,blank}`, `reservations.activity.{transition.{check_in,check_out,cancel},edit.*,comment}`; activity field labels reuse `activerecord.attributes.reservation.*`.

### Tests

- Model: `ReservationActivity` (validations, readonly); `Reservation` (predicates, wrappers, `add_comment`, `log_*`); `Room.available_between(except:)`.
- Service: `ReviseReservation` (reschedule/room/rate happy paths, tiered violation → `EditNotAllowed`, overlap → `RoomUnavailable`, past → `PastDate`, logs one `edit`, no-op on empty); `CheckOut` logs transition.
- Request: `show`/`edit` render; `update` success+conflict+invalid+past; comment create + blank; lifecycle-from-show redirects to show & logs; row links to show.

## Design Summary

**Status: Approved -- ready for implementation** (2026-06-15)

- **Components / layers**: Models — `ReservationActivity` (new aggregate child), `Reservation` extensions (activity assoc, tiered predicates, entry constructors, lifecycle wrappers), `Room.available_between(except:)`. Services — `Reservations::ReviseReservation` (new), `CheckOut` (extend with actor+log), `EditNotAllowedError` (new). Controllers — `ReservationsController#show/edit/update` + lifecycle redirect to show, `Reservations::CommentsController#create`. Views/Stimulus — `show`/`edit`/`_activity`, reused `available_rooms` frame + `availability` controller, slimmed `_reservation_row`.
- **Key contracts**: `reservation_activities` schema (append-only, `details` JSON, created_at only); `ReviseReservation` keyword signature; `Room.available_between(period, except:)`; routes add `show/edit/update` + nested `comments#create`; activity `details` shapes (`{event}`, `{changes:{field:[from,to]}}`).
- **Architectural constraints**: first aggregate child owned via `dependent: :destroy`, reached only through `reservation.activities`; spanning invariant + transaction in the service reusing `available_between`; model-vs-service asymmetry per architecture.md §8; no AASM callbacks for logging; actor passed in (no `Current` in models); thin controllers; all strings I18n (structured `details`, localized at render); edit/FK/date inputs guarded at the HTTP boundary → 422.
- **Domain decisions**: unified persisted activity log (lifecycle + edits + comments); tiered-by-state edit policy; append-only authored comments; rate is an overwrite of the snapshot; reschedule reuses the past-date and availability guards from booking.
- **Resolved questions**: timeline = persisted unified log; edit policy = tiered; comments = append-only; edit UX = separate page; all actions on show page only (lifecycle now redirects to show).
- **Next step**: `/code-forge` against this blueprint, delivered as three domain-scoped PRs (confirmed 2026-06-15):
  - **PR 1 — Activity log foundation**: `reservation_activities` migration + `ReservationActivity` model; `Reservation` activity assoc, tiered predicates, `log_transition`/`log_edit`/`add_comment`, `check_in_by!`/`cancel_by!`; extend `Reservations::CheckOut` with `actor:` + logging; wire existing lifecycle controller actions to pass `actor:`. Model/service/request specs. (No UI yet — existing pages keep working; entries start accruing.)
  - **PR 2 — Reservation show page**: `reservations#show` + view (summary, guest panel, room panel, activity feed `_activity`), `Reservations::CommentsController#create` + comment form, `_reservation_row` code→link and row buttons moved to show, lifecycle actions redirect to show. i18n + request specs.
  - **PR 3 — Edit / revise**: `Reservations::ReviseReservation` + `EditNotAllowedError`, `Room.available_between(except:)`, `reservations#edit`/`update`, edit view reusing the `available_rooms` frame, tiered field gating. Service/request specs.
  - Each PR on its own branch off `main`, green suite before merge.

## Key Files

<!-- Add as dev progresses. List paths with brief role note. -->

