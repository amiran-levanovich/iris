# Operational Learnings

Actionable patterns harvested from practice. Loaded at the start of design/implementation sessions; tightened over time.

## Design

- **Zero-services CRUD is valid** (2026-06-11, Properties & Rooms design): Under Rails MVC+, a feature whose writes all stay inside one aggregate legitimately has no service objects. Check the anemic-service anti-pattern in `architecture.md` before scaffolding services; controllers calling models directly is the correct shape for single-aggregate CRUD.
- **Guard enum params at every HTTP boundary** (2026-06-11, Properties & Rooms review): Rails string enums raise `ArgumentError` on mass-assigned unknown values — they do not produce validation errors. Every controller action that accepts an enum param needs a rescue/guard mapping to 422, not just the obvious status-change action; the form's `<select>` is not the trust boundary.
- **Name states for what they assert** (2026-06-11, Properties & Rooms design): Choose domain vocabulary that won't collide with future derived concepts. A room is `operational`, not `available` — availability is derived from reservations later. When naming an enum value, ask what adjacent features will need the obvious word for.
