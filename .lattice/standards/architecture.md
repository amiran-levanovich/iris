---
mode: override
---

> These are the architecture principles for Iris, following a **Rails MVC+** architecture: standard Rails conventions plus an explicit service layer for multi-model workflows. This document is the sole reference for the `architecture` atom — there are no embedded defaults.

**Table of contents:**

1. [Layer Definitions](#1-layer-definitions)
2. [Dependency Rules](#2-dependency-rules)
3. [Boundary Rules](#3-boundary-rules)
4. [Per-Layer Rules](#4-per-layer-rules)
5. [Key Flows](#5-key-flows)
6. [Validation Checklist](#6-validation-checklist)
7. [Anti-Patterns](#7-anti-patterns)
8. [Ambiguity Signals](#8-ambiguity-signals)

---

## 1. Layer Definitions

| Layer | Responsibility | Typical Directory |
|-------|---------------|-------------------|
| Controllers | HTTP only: params, auth, calling a model or service, rendering/redirecting | `app/controllers/` |
| Views | Presentation: ERB templates, Turbo frames/streams, partials, helpers | `app/views/`, `app/helpers/` |
| Models | Domain rules: AR models with validations, scopes, associations, single-model behavior; value objects as POROs | `app/models/` |
| Services | Multi-model workflows ("check in guest", "create reservation with conflict check"), one PORO per use case | `app/services/` |
| Jobs | Async wrappers that delegate to models/services, no business logic of their own | `app/jobs/` |
| Stimulus | Client-side sprinkles only; server stays the source of truth | `app/javascript/controllers/` |

### Directory Mapping

```
app/
├── controllers/   # HTTP layer
├── views/         # Presentation
├── helpers/       # View-only formatting
├── models/        # Domain: AR models + POROs/value objects
├── services/      # Use-case workflows (e.g., reservations/create_reservation.rb)
├── jobs/          # Solid Queue jobs, thin
└── javascript/    # Stimulus controllers
```

---

## 2. Dependency Rules

```
Views ──▶ Helpers
  │
Controllers ──▶ Services ──▶ Models
  │                            ▲
  └────────────────────────────┘   (controllers may call models directly for simple CRUD)
Jobs ──▶ Services / Models
```

- Models depend on nothing above them — never reference controllers, views, helpers, params, or `Current` request state.
- Services depend only on models (and other services); never on controllers, views, or HTTP concepts.
- Controllers call services for multi-model workflows and models directly for simple CRUD. They never contain the workflow itself.
- Jobs delegate immediately to a service or model method.

**Data crossing boundaries**: plain values and AR objects. Controllers pass primitives/keyword args into services (never the `params` object). Services return the affected record(s) or raise a domain error; they do not render or redirect.

---

## 3. Boundary Rules

- Direct method calls everywhere — no event bus, no mediators.
- Dependency injection is manual: services take collaborators as keyword arguments with sensible defaults (per the language-idioms document).
- Services expose a single public entry point: `ServiceName.new(...).call` (or `.call(...)` class shortcut).
- Strong parameters live in controllers (`params.expect`); services receive already-extracted values.
- Turbo Streams responses are assembled in controllers/views, never inside services or models.

---

## 4. Per-Layer Rules

### Controllers

**What belongs here:** routing-adjacent logic — authentication checks, `params.expect`, one service or model call, respond with HTML/Turbo Stream/redirect, flash messages.

**What does not belong here:** multi-step business workflows, queries beyond a scope call, transactions, calls to `Model.where(...)` chains that encode domain rules.

**Common violations:** business conditionals in actions; building records for several models inline; rescuing domain errors in many actions instead of `rescue_from`.

### Models

**What belongs here:** validations, associations, scopes, state predicates (`room.occupied?`), single-model commands (`reservation.cancel!`), callbacks limited to the model's own data.

**What does not belong here:** knowledge of HTTP/session, calls to services, mailers or jobs triggered from callbacks for cross-model effects, formatting for views.

**Common violations:** callback chains that touch other aggregates; view formatting methods (use helpers); god models absorbing what should be a service.

### Services

**What belongs here:** one use case per class, named with a verb (`CheckInGuest`, `CreateReservation`); the transaction boundary; orchestration of several models, mailers, and jobs; raising domain errors.

**What does not belong here:** rendering, params parsing, session access, generic "manager"/"processor" grab-bag classes.

**Common violations:** service calling another controller concern; services that are just one-line model delegations (inline those into the model); accumulating class-level state.

### Views / Helpers

**What belongs here:** markup, partials per resource, Turbo frames/streams, helpers for formatting only.

**What does not belong here:** queries (`Model.where` in ERB), business decisions beyond simple display conditionals.

**Common violations:** N+1s introduced by templates (preload in controller); logic-heavy helpers that belong on models.

### Jobs

**What belongs here:** a `perform` that delegates to a service or model method; retry/queue configuration.

**What does not belong here:** business logic bodies; multi-step workflows written inline.

**Common violations:** copy-pasting service logic into `perform`; jobs serializing whole objects instead of ids.

---

## 5. Key Flows

### Flow 1: Write operation (create a reservation)

```
1. ReservationsController#create — authenticates, extracts values via params.expect
2. Reservations::CreateReservation.call(guest:, room:, check_in:, check_out:)
   — opens transaction, checks availability, creates Reservation, enqueues confirmation job
3. Service returns the reservation (or raises Reservations::RoomUnavailableError)
4. Controller redirects (success) or re-renders form with errors / rescues domain error
```

### Flow 2: Read operation (room board)

```
1. RoomsController#index — authenticates
2. Calls model scopes directly: property.rooms.with_current_reservations (preloaded)
3. View renders partials; Turbo frames for per-room detail
```

---

## 6. Validation Checklist

STOP after generating each component. Verify ALL of the following before proceeding:

1. **LAYER PLACEMENT**: Is each new class in the correct directory for its role (workflow → `app/services/`, domain rule → `app/models/`)?
2. **DEPENDENCY DIRECTION**: Do models avoid referencing controllers/views/params/Current? Do services avoid HTTP concepts?
3. **CONTROLLER THINNESS**: Does each action do at most auth + params + one model/service call + respond?
4. **TRANSACTION BOUNDARY**: Are multi-model writes wrapped in a transaction owned by the service (not the controller, not callbacks)?
5. **BOUNDARY DATA**: Are services receiving extracted values/keyword args, never the raw `params` object?
6. **QUERY PLACEMENT**: Are query chains expressed as named scopes/model methods, not inline `where` chains in controllers or views?

---

## 7. Anti-Patterns

After verifying the checklist above, scan output for these anti-patterns. If found, fix before presenting.

- [ ] **Fat controller**: action contains conditionals/loops implementing a business rule → extract to a service or model method.
- [ ] **Callback side-effects**: AR callback sends email, touches another aggregate, or enqueues cross-model work → move to the service that owns the use case.
- [ ] **Params leakage**: `params` or controller state passed into a service/model → extract values in the controller, pass keywords.
- [ ] **Anemic service**: service is a one-line delegation to a single model → inline it into the model and delete the service.
- [ ] **God model**: model accumulating workflow methods touching several other models → extract a verb-named service per use case.
- [ ] **View queries**: `Model.where`/`find` calls inside ERB or helpers → move to controller with preloading, expose via instance variable.

---

## 8. Ambiguity Signals

These checks often have multiple valid outcomes. When you encounter one, present options rather than silently choosing.

- A behavior touches exactly one model but is triggered alongside others (e.g., `reservation.cancel!` plus a notification) — model method, service, or both? Default: model owns the state change, service owns the orchestration; ask when unclear.
- A piece of logic could be a concern shared across models vs duplicated in two models — ask once duplication reaches a third site.
- Turbo Stream vs full redirect for a write response — UX judgment; ask if the page context is unclear.

---

*Generated for Iris on 2026-06-11. Style: Rails MVC+ (custom).*
*Produced by the architecture-refiner skill.*
