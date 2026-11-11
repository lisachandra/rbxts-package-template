<div align="center">
  <h1>rbxts-package-template</h1>

  <p>
    <strong>A monorepo template for publishable roblox-ts packages.</strong>
  </p>

![CI Status][ci-badge] ![Test Results][test-results-badge]
![Test Coverage][test-coverage-badge] ![Version][version-badge]

[ci-badge]: https://github.com/lisachandra/rbxts-package-template/actions/workflows/ci.yaml/badge.svg
[test-results-badge]: https://gist.githubusercontent.com/lisachandra/df57d44f003b280db81b6ddb1aec81ba/raw/test-results-badge.svg
[test-coverage-badge]: https://gist.githubusercontent.com/lisachandra/df57d44f003b280db81b6ddb1aec81ba/raw/test-coverage-badge.svg
[version-badge]: https://gist.githubusercontent.com/lisachandra/df57d44f003b280db81b6ddb1aec81ba/raw/version-badge.svg

</div>

A general-purpose Roblox monorepo package template built with roblox-ts, pnpm, the
`@lisachandra` runtime stack, and a strict build/lint/typecheck/emulated test pipeline.

## Core Features

- **`sloptor` replaces `rbxtsc`** — a native TypeScript→Luau compiler and type
  checker in one binary. It builds packages with `--type package` (emitting the
  declarations a published package ships) and runs the strict typecheck from
  the same tool.
- **Offline emulated test lane** — `pnpm test` compiles each `test/<name>`
  workspace to Luau and runs its suite inside `ree`, a headless Roblox engine
  reimplementation. No Studio roundtrip, no uploaded place, no credentials, and
  CI needs no Roblox secrets. Specs with engine parity gaps are listed in
  `reeParityPaths` (`jest.shared.ts`) and run against Studio with
  `--backend studio`.
- **Interactive setup** — `bash scripts/setup-template.sh` walks through
  package naming and scoping, Roblox ids, the npm publish token, badge gists,
  and CI secrets, then installs and builds.

## Toolchain Credits

The compiler, emulator, and jest runner are personal forks of public projects:

| Tool                     | Upstream                                                                                                            | Fork adds                                                                     |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| `sloptor`                | [`howmanyslop/sloptor`](https://github.com/howmanyslop/sloptor)                                                     | Pinned fork build; `--type package` emits the declarations each package ships |
| `ree`                    | [`Anime-Vanguards/roblox-engine-emulator`](https://github.com/Anime-Vanguards/roblox-engine-emulator)               | Pinned commit with the harness fixes (GPL-2.0-or-later)                       |
| `@isentinel/jest-roblox` | [`christopher-buss/jest-roblox-cli`](https://github.com/christopher-buss/jest-roblox-cli) by Christopher Buss (MIT) | The `emulator` backend that runs jest suites inside `ree`                     |

Forks are consumed as release binaries and tarballs, never vendored.

## Requirements

- [mise](https://mise.jdx.dev) (pins node/pnpm/rojo/gh/jq)
- pnpm
- Git

## Setup Wizard (recommended)

Creating a project _from_ this template? Run the interactive wizard instead of
configuring by hand:

```bash
bash scripts/setup-template.sh
```

It walks you through renaming `packages/example` and `test/example`, your
Roblox Open Cloud test credentials, the npm publish token, badge gists, and
GitHub CI secrets, then installs and builds.

The wizard is for a fresh copy only — it rewrites tracked files in place, so do
not run it inside the template repository itself. For the full manual path,
including adding a package and the Studio lane, see
[`docs/agents/setup-guide.md`](docs/agents/setup-guide.md).

## Getting Started

```bash
pnpm setup
```

## Adding a Package

1. Create `packages/<name>/` with `package.json`, `tsconfig.json`,
   `default.project.json`, and `src/`.
2. Name it `@lisachandra/<name>` and keep the `exports`/`main`/`types`
   convention (`out/init.luau`, `out/index.d.ts`).
3. Create `test/<name>/` with its own `default.project.json` (a DataModel
   test place), `jest.config.ts` (extending `../../jest.shared.ts`), and
   `src/**/*.spec.ts`.
4. Add both `packages/<name>` and `test/<name>` to the root `tsconfig.json`
   references, and declare `workspace:*` dependencies as needed.
5. Run `pnpm install`, then `pnpm build:packages` and `pnpm build:test`.

## Testing

Each `test/<name>` project builds a minimal Roblox place with
`sloptor build --type game` and runs jest-roblox:

- Locally and in CI: `pnpm test` uses the `emulator` backend — the compiled
  `out/` tree is staged and run inside `ree`, offline, with no Studio and no
  Roblox credentials.
- To confirm a spec against a real engine, run it with `--backend studio`
  against a local Studio install.
- `test/example/src/jest.config.luau` is the per-project Luau config the staged
  runner reads; `jest.shared.ts` holds the backend and coverage settings every
  project inherits.

## Status Badges

The CI workflow updates the test, coverage, and version badges in a public
gist using `schneegans/dynamic-badges-action`. To enable it:

1. Set the repository variable `CI_BADGE_GIST_ID` to your gist ID.
2. Create a GitHub personal access token with the `gist` scope and set it as
   the `GIST_SECRET` repository secret.
3. Point the badge links at the top of this file at your gist ID.

## Releases

Releases are changesets-based and driven by the
[release workflow](.github/workflows/release.yaml):

1. `pnpm changeset` for each user-facing change.
2. Dispatch the `Release` workflow from GitHub Actions.
3. The workflow validates build/tests, runs `pnpm version` (changesets),
   commits, publishes changed packages to npm, tags the release, and pushes.

Requires repository secrets: `NPM_TOKEN`, plus `ROBLOX_OPEN_CLOUD_API_KEY`,
`ROBLOX_PLACE_ID`, and `ROBLOX_UNIVERSE_ID` for the test gate.

## Renaming the Template

The placeholder package is `packages/example` (`@lisachandra/example`) with
`test/example` (`@lisachandra/test-example`). To reuse the template:

1. Rename `packages/example` → `packages/<name>` and `test/example` →
   `test/<name>`.
2. Update package names, `workspace:*` references, and the root
   `tsconfig.json` references.
3. Update the repository URLs in root/package manifests and the `repo` field
   in `.changeset/config.json`.
4. Update this README and `AGENTS.md` to taste.

## License

MIT © 2026 lisachandra
