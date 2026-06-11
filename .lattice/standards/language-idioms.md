---
language: ruby
version: "3.4"
---

# Language Idioms: Ruby (Rails 8.1)

## Error Handling

Exceptions for exceptional cases, not control flow. Custom error classes inherit from `StandardError` (never `Exception`). Rescue the narrowest class that makes sense; never bare `rescue`. Follow ActiveRecord's bang/non-bang convention: `save!`/`create!` raise inside transactions and jobs, `save`/`create` return booleans for user-facing flows that render validation errors. No Result/monad gems in v1 -- service outcomes are expressed via return values and raised domain errors.

## Type System & Object Model

Dynamically typed with duck typing; design to messages, not types. Classes plus modules for shared behavior (concerns in Rails); composition over inheritance -- inheritance only for true is-a (e.g., `ApplicationRecord` subclasses). Value objects use `Data.define` (Ruby 3.2+) with `Comparable` where ordering matters. `# frozen_string_literal: true` in every file (omakase default). No Sorbet/RBS type checking in this project.

## Naming Conventions

`snake_case` for methods, variables, and file names; `CamelCase` for classes/modules; `SCREAMING_SNAKE_CASE` for constants. Predicate methods end in `?` and return booleans; dangerous variants (mutating or raising) end in `!` only when a safe twin exists. No `get_`/`set_` prefixes -- attribute readers/writers are bare nouns. File path mirrors module nesting (Zeitwerk).

## Testing Patterns

RSpec with `describe`/`context`/`it`; `context` strings start with "when"/"with". One behavior focus per example. FactoryBot for test data: prefer `build`/`build_stubbed` over `create` when the database isn't needed; factories define minimal valid records, traits for variations. Minimal mocking: real objects preferred; verifying doubles (`instance_double`) only at process boundaries (HTTP clients, mailers, clock). Spec types by directory: `spec/models`, `spec/requests`, `spec/system`.

## Parameter & Function Design

Keyword arguments whenever a method takes more than one parameter; defaults declared in the signature. No untyped options-hash (`opts = {}`) pattern. Methods stay short, return values rather than mutating arguments, and use implicit return of the last expression. Multiple values returned via small value objects or arrays with destructuring, not out-params.

## Dependency Management

No DI container. Manual constructor injection with keyword defaults (`def initialize(clock: Time.zone)`) so collaborators are swappable in specs without stubs. Rails autoloading via Zeitwerk -- no `require` for code under `app/`; `require` only for stdlib/gems in `lib/`. Gem dependencies live in the `Gemfile` grouped by environment.

---
*Generated for Iris on 2026-06-11.*
*Produced by the language-idioms-refiner skill.*
