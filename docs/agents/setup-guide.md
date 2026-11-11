# Setup Guide

Everything needed to take a fresh clone of a project created from this template
to a running build and test lane. Follow in order; each step states what
"done" looks like.

> **Fresh copy only.** This guide and `scripts/setup-template.sh` are for a
> project created _from_ the template. Neither applies inside the template
> repository itself — it is already set up, and the wizard rewrites tracked
> files in place.

## 0. Prerequisites

| Tool                         | Why                              | Install                |
| ---------------------------- | -------------------------------- | ---------------------- |
| [mise](https://mise.jdx.dev) | pins every binary below          | see mise docs          |
| Git                          | repository, submodules, releases | system package manager |
| Node 26 / pnpm 12            | provided by mise                 | —                      |

`mise.toml` pins the toolchain. Nothing else needs a global install except
mise itself.

**Done when:** `mise --version` works.

## 1. Install the toolchain

```bash
mise install
```

This fetches every pinned binary, including two you will not find on npm:

| Binary         | Role                                                        | Source          |
| -------------- | ----------------------------------------------------------- | --------------- |
| `sloptor`      | TypeScript→Luau compiler, type checker, declaration emitter | release fork    |
| `ree`          | roblox-engine-emulator; runs the default test lane offline  | release fork    |
| `rojo`, `lune` | project build, Luau scripting                               | public releases |

**Done when:** `sloptor version`, `ree --version`, and `rojo --version` all
print a version.

## 2. Project setup

```bash
pnpm setup
```

Runs a frozen install and a full build of every package and test project.

**Done when:** each `packages/<name>/out/` exists and `pnpm typecheck` passes.

## 3. Configure secrets

Copy `.env.example` to `.env` and fill what you need. Every value is optional
for local development:

| Variable                    | Needed for                                  |
| --------------------------- | ------------------------------------------- |
| `ROBLOX_OPEN_CLOUD_API_KEY` | Open Cloud test lane, release workflow gate |
| `ROBLOX_UNIVERSE_ID`        | Open Cloud test lane, release workflow gate |
| `ROBLOX_PLACE_ID`           | Open Cloud test lane, release workflow gate |

The default lane needs none of these: `pnpm test` runs offline inside `ree`.
The Open Cloud triple is only read by the Studio/Open Cloud lane and by the
release workflow's optional test gate.

**Done when:** `.env` exists and is git-ignored.

## 4. Test lane

```bash
pnpm test                                              # every test workspace, emulated
pnpm --filter @lisachandra/test-<name> test            # one workspace
pnpm --filter @lisachandra/test-<name> test --testPathPattern "<pattern>"
```

The default lane runs compiled Luau inside `ree`, offline. Specs listed in
`reeParityPaths` (`jest.shared.ts`) are skipped by the emulator and run against
a real Studio install with `--backend studio`, because ree does not emulate
everything — see `docs/agents/offline-runtime-spike.md`.

**Done when:** `pnpm test` is green.

## 5. Adding a package (optional)

1. Create `packages/<name>/` with `package.json`, `tsconfig.json`,
   `default.project.json`, and `src/`.
2. Create `test/<name>/` with its own `default.project.json`,
   `jest.config.ts` extending `../../jest.shared.ts`, and `src/**/*.spec.ts`.
3. Add a `src/jest.config.luau` to the test project — the emulator stage reads
   it inside the compiled tree:

    ```lua
    return {
        testMatch = { "**/*.spec" },
        testPathIgnorePatterns = { "/node_modules/", "/dist/", "/out/" },
        mockDataModel = false,
        clearMocks = true,
        testTimeout = 300000,
        displayName = "<name>",
    }
    ```

4. Add both `packages/<name>` and `test/<name>` to the root `tsconfig.json`
   references, and declare `workspace:*` dependencies.
5. Run `pnpm install`, then `pnpm build:packages` and `pnpm build:test`.

**Done when:** `pnpm test --filter @lisachandra/test-<name>` is green.

## 6. Studio lane (only when ree disagrees)

```bash
pnpm --filter @lisachandra/test-<name> test -- --backend studio
```

Needs a Roblox Studio install. If the runner times out with
`Timeout reached while waiting for Roblox Studio to come online` on Windows:

```powershell
net stop winnat
net start winnat
```

Then reopen Studio and retry.

**Done when:** the targeted spec passes on the Studio backend.

## 7. Release setup (only when publishing)

Releases are changesets-based and driven by `.github/workflows/release.yaml`:

1. `pnpm changeset` for each user-facing change.
2. Dispatch the `Release` workflow from GitHub Actions.
3. The workflow builds, runs the test gate, versions, publishes to npm, tags,
   and pushes.

Requires `NPM_TOKEN`; the test gate runs when the Open Cloud triple is present.

**Done when:** the release workflow publishes the changed package.

## Troubleshooting

| Symptom                                    | Cause                                      | Fix                                                         |
| ------------------------------------------ | ------------------------------------------ | ----------------------------------------------------------- |
| `sloptor: not found`                       | mise not activated                         | `mise install`, then `mise trust`                           |
| Build emits `.luau` but plugins do nothing | missing `rotor.toml` with a plugin section | restore `rotor.toml` — it is load-bearing                   |
| `ERR_PNPM_LOCKFILE_CONFIG_MISMATCH`        | CRLF in `patches/**`                       | `.gitattributes` pins `patches/** text eol=lf`; re-checkout |
| Test spec fails only on emulator           | ree parity gap                             | add the path to `reeParityPaths`, log it in the ledger      |
| `no tests found` in an unrelated workspace | root test fans the pattern out             | filter to one workspace first, or pass `--passWithNoTests`  |
| Instance name rejected on Windows          | `$path` node name contains `:`             | rename the node — `:` is not a valid directory character    |
