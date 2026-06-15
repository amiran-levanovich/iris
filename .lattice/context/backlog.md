---
feature: Planned Features Backlog
requirement_doc: null
created: "2026-06-15"
---

# Planned Features Backlog

> A running list of features deliberately deferred ("out of scope") across Iris design sessions. Each was a conscious cut, not an oversight — recorded here so they aren't lost. Source column points at the design that deferred it. Not prioritized; this is a holding list, not a roadmap.

## Billing & money

| Feature | First deferred by | Notes |
|---------|-------------------|-------|
| Payments / invoices / folios | Guests & Reservations | Reaffirmed in Reservations Console and Reservation Detail |
| Rate plans / seasonal pricing | Guests & Reservations | Today a single flat `nightly_rate_cents` snapshot per reservation |
| Multi-currency | Properties & Rooms | Money is integer cents, single currency |

## Distribution & channels

| Feature | First deferred by | Notes |
|---------|-------------------|-------|
| OTA / channel-manager sync | Guests & Reservations | No external integrations in v1 |
| Global cross-property reservations view | Reservations Console | Lists are property-scoped today |

## Booking depth

| Feature | First deferred by | Notes |
|---------|-------------------|-------|
| Group bookings | Guests & Reservations | One guest per reservation today |
| Overbooking rules | Guests & Reservations | Hard overlap refusal only |
| No-show automation | Guests & Reservations | Lifecycle is staff-driven |
| Partial-night / hourly stays | Reservation Detail | Date-granular stays only |
| Split / merge reservations | Reservation Detail | — |
| Undo / restore a cancelled reservation | Reservation Detail | Cancellation is terminal |

## Reservation detail (this feature's deferrals)

| Feature | First deferred by | Notes |
|---------|-------------------|-------|
| Editing guest identity from the reservation page | Reservation Detail | Guests have their own edit pages |
| Change notifications / emails on edits | Reservation Detail | Activity log records changes; no outbound mail |

## Maintenance

| Feature | First deferred by | Notes |
|---------|-------------------|-------|
| Property-wide maintenance board | Maintenance Requests | Per-room only today |
| Per-request blocking flag (vs every active request blocks) | Maintenance Requests | — |
| Cost / parts tracking | Maintenance Requests | — |
| Recurring maintenance | Maintenance Requests | — |
| Attachments on requests | Maintenance Requests | — |
| Remember non-maintenance prior room status on restore | Maintenance Requests | — |

## Ops dashboards & housekeeping

| Feature | First deferred by | Notes |
|---------|-------------------|-------|
| Date-ranged reservation history | Property Ops Overview | — |
| Multi-day occupancy forecast | Property Ops Overview | — |
| Drag/drop room board | Property Ops Overview | — |
| Turbo Streams for ops actions (replace plain redirects) | Property Ops Overview | — |

## Console & lists

| Feature | First deferred by | Notes |
|---------|-------------------|-------|
| Export (reservations) | Reservations Console | — |
| Pagination beyond a sensible cap | Reservations Console | — |

## Platform / polish

| Feature | First deferred by | Notes |
|---------|-------------------|-------|
| Pretty URLs / `to_param` | Reservation Reference Codes | Reservation codes exist but URLs use ids |
| Room / property photos | Properties & Rooms | — |
| Staff sign-in management UI | Properties & Rooms | Auth exists; no admin UI for users |

## Delivered since deferral (kept for the record)

- **Reservation show page** — deferred by Reservation Reference Codes and Reservations Console; **delivered by Reservation Detail & Management** (2026-06-15).
- **Editing a reservation's dates / room after booking** — deferred by Reservations Console; **delivered by Reservation Detail & Management** (2026-06-15).
