# Agent Instructions

- Use `./.tmp/` for temp files. No OS temp.
- Use **pnpm** for package management and `./scripts/build.mjs` scopes
  (`all`, `packages`, `test`) for builds.

## References

- [Setup guide](docs/agents/setup-guide.md): fresh copy → build, test lane, adding a package.
- [Offline runtime parity ledger](docs/agents/offline-runtime-spike.md): what the
  emulator test lane does and does not emulate.

## Setup

```bash
pnpm setup
```

`sloptor` (the compiler) and `ree` (the emulator test backend) come from
`mise.toml`. Run `mise install` once, or prefix with `mise x --`.

## Commands

| Task           | Command               |
| -------------- | --------------------- |
| Build all      | `pnpm build`          |
| Build packages | `pnpm build:packages` |
| Build tests    | `pnpm build:test`     |
| Dev (watch)    | `pnpm dev`            |
| Lint           | `pnpm lint:fix`       |
| Typecheck      | `pnpm typecheck`      |
| Test           | `pnpm test`           |
| Changeset      | `pnpm changeset`      |
| Version        | `pnpm version`        |
| Release        | `pnpm release`        |

## Commit Attribution

AI commits MUST include:

```text
Co-Authored-By: (the agent's name and attribution byline)
```

## Agent Workflow

- Check matching GitHub issue/sub-issue when useful. Mention in plan and
  summary.
- Before changeset: check related changesets. Avoid duplicate.
- One commit may have many changesets when user-facing behaviors differ.
- After work: create/update issues for material follow-up. Do not bury follow-up
  in chat.

## Verification

- `pnpm lint:fix`, `pnpm typecheck`, `pnpm build`
- Always use the most efficient test option:
    - selective tests: `pnpm --filter @lisachandra/test-<name> test --testPathPattern <pattern>`
    - all tests: `pnpm test`
- Report exact tests/tools run and blockers.

## Project Conventions

- Packages live in `packages/<name>` and their test projects in `test/<name>`.
- Package names are `@lisachandra/<name>`; test packages are
  `@lisachandra/test-<name>` and private.
- Workspace deps use `workspace:*`; tooling versions come from the pnpm
  catalog in `pnpm-workspace.yaml`.
- Release notes are changesets; every user-facing change gets one.

## Testing

Each `test/<name>` workspace is one Rojo project with its own
`jest.config.luau`. The default lane is the **emulator** backend: it stages the
compiled `out/` tree and runs it inside `ree`, offline, with no Studio
roundtrip. `pnpm test` fans out across every test workspace in parallel.

A spec that only fails under the emulator is a parity gap, not a broken test.
Add it to `reeParityPaths` in `jest.shared.ts` and record the symptom in the
ledger. `--backend studio` runs the same config against a real Studio install
when you need to confirm.

Container folders a spec indexes at require time must be declared in the test
project's `default.project.json` as a `$path` mount — the stage only materialises
`$path` nodes, and instance names must be valid directory names on every
platform (no `:` on Windows).
