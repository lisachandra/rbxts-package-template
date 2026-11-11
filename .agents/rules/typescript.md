---
paths:
  - "src/**/*.ts"
  - "src/**/*.tsx"
  - "packages/*/src/**/*.ts"
  - "packages/*/src/**/*.tsx"
---

# TypeScript (Roblox-TS)

- TypeScript strict mode
- No `any` types (use `unknown` if type truly unknown)
- No type assertions / casts (`as`, `<T>`, `!`) - ever. Use strict type guards.
- Prefer `fn(options: Options)` over positional parameters. Max 2 parameters.
- Factory functions for object creation (not classes)
- `readonly` on all data structure properties
- No `Attempted to assign non-method where method was expected.` errors
- No reserved compiler usage identifiers. (error, TS, unpack, type/typeof)

## Logging

- `@rbxts/log` is the only logging surface: `import Log from "@rbxts/log"`. Never call `print`,
  `warn`, or `error` outside the sink (`packages/core/src/logger.ts`).
- Levels: `Log.Debug`/`Log.Verbose` for diagnostics, `Log.Info` for lifecycle events, `Log.Warn` for
  recoverable or degraded problems, `Log.Fatal` when control flow must stop.
- `Log.Fatal` is the halting level and is typed `never` (`patches/@rbxts__log.patch`) - delete
  unreachable code after it instead of adding `return`/`break`. `Log.Error` is not the halting level.
- Never wrap `Log.*` or `LogService.Log` in `pcall`; the sink owns the error mapping.
- Enforced by the `project/logging` block in `oxlint.config.ts`; see `docs/agents/coding-standards.md`.
