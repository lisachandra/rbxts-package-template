# Offline Runtime Spike — parity ledger

The default test lane runs compiled Luau inside `ree`
(roblox-engine-emulator) instead of Roblox Studio. That trades startup cost
and a Studio dependency for a reimplementation that does not implement the
whole engine. This file is the ledger of where the two disagree.

Packages are published from this repo, so a spec that reaches outside the
emulated surface is a signal that the package under test depends on an engine
feature — record it here rather than hiding it in a skipped test.

## What ree emulates

- The DataModel tree, `Instance` construction and property access.
- Signals, the scheduler, `task.*`, and virtual time with `RunService` frame
  phases.
- `require` over a Rojo project, including `WaitForChild`.
- Attributes.

## What ree does not emulate

- Remotes and networking.
- `HttpService` requests.
- Physics beyond free fall.
- `ReflectionService:GetClasses()` — `scripts/emulator/reflection.json`
  supplies a static copy for staging (see `scripts/emulator/README.md`).
- Studio-only services and the DataModel services that back them.

## Working with a parity gap

A spec that fails only on the emulator is a **parity gap**, not a broken test.

1. Reproduce with a targeted run:
   `pnpm --filter @lisachandra/test-<name> test --testPathPattern "<path>"`.
2. Confirm the spec passes on real Roblox (Studio lane, `--backend studio`).
3. Add the spec path to `reeParityPaths` in `jest.shared.ts`, with a one-line
   comment saying what ree does not do.
4. Add an entry here: the spec, the symptom, what it needs, and whether an
   upstream ree fix would remove it.

## Ledger

Empty in the template. Record entries as they are found.

| Spec | Symptom | Needs | Upstream fix? |
| ---- | ------- | ----- | ------------- |
