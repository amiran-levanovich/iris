# Operational Learnings

Actionable patterns harvested from practice. Loaded at the start of design/implementation sessions; tightened over time.

## Design

- **Zero-services CRUD is valid** (2026-06-11, Properties & Rooms design): Under Rails MVC+, a feature whose writes all stay inside one aggregate legitimately has no service objects. Check the anemic-service anti-pattern in `architecture.md` before scaffolding services; controllers calling models directly is the correct shape for single-aggregate CRUD.
- **Name states for what they assert** (2026-06-11, Properties & Rooms design): Choose domain vocabulary that won't collide with future derived concepts. A room is `operational`, not `available` — availability is derived from reservations later. When naming an enum value, ask what adjacent features will need the obvious word for.
