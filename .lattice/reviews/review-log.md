# Review Log

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
