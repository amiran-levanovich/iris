# Review Log

## 2026-06-15 — Maintenance Requests (branch feature/maintenance-requests)
- **Scope**: 21 files; model, services, controllers, views, routes, i18n, css, specs (new aggregate + cross-aggregate room-status coupling)
- **Atoms**: clean-code, architecture, domain-driven-design, secure-coding, test-quality
- **Result**: 0 critical, 1 warning, 1 suggestion (both fixed)
- **Key findings**: crafted assignee_id for a missing user hit the DB FK → 500 not 422 (fixed: model `assignee_must_exist` validation); maintenance_requests used `dependent: :destroy` vs reservations' `:restrict_with_error` (fixed: aligned)
- **Strengths**: OpenRequest/CloseRequest own transactions with "release room iff no other active" guard; CheckOut patched so checkout can't drop an active maintenance block; active_for queried inside the service, not reached from Room

## 2026-06-13 — Property Ops Overview (branch feature/property-ops-overview, a5af33b)
- **Scope**: 14 files; controllers, views, routes, i18n, css, specs (presentation + read-query redesign)
- **Atoms**: clean-code, architecture, secure-coding, test-quality
- **Result**: 0 critical, 1 warning, 0 suggestion
- **Key findings**: properties#show queried the same checked-in set twice (@current_reservations + @in_house) — collapsed by indexing @in_house
- **Strengths**: fold-in deleted a whole action/route/2 templates; redirect retargeting consistent across 5 sites; no coverage lost

## 2026-06-13 — Guests & Reservations (branch feature/guests-reservations, 6a3630f)
- **Scope**: 41 files; models, services, controllers, views, helpers, migrations, routes, specs
- **Atoms**: clean-code, architecture, domain-driven-design, secure-coding, test-quality
- **Result**: 0 critical, 1 warning, 4 suggestion
- **Key findings**: availability rule duplicated between Room.available_between and BookRoom (DRY); overlap check-then-create is TOCTOU (SQLite-safe only); reservation status pills lack CSS color variants
- **Strengths**: services own transactions; AASM lifecycle with no cross-aggregate callbacks; status kept out of strong params; half-open + illegal-transition specs

## 2026-06-11 — Properties & Rooms (commits 4ffeb73, f0036b2, 58846c0)
- **Scope**: ~30 files; models, controllers, views, routes, specs, locales
- **Atoms**: clean-code, architecture, domain-driven-design, secure-coding, test-quality
- **Result**: 0 critical, 1 warning, 3 suggestion
- **Key findings**: unknown enum value via raw HTTP → 500 in rooms create/update; status-button logic inline in show template; flash rendering duplicated per-view
- **Strengths**: consistent aggregate access through property.rooms; failure-path request specs; raise_on_missing_translations enforces i18n invariant
