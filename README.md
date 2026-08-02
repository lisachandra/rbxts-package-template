<div align="center">
  <h1>rbxts-package-template</h1>

  <p>
    <strong>A monorepo template for publishable roblox-ts packages.</strong>
  </p>
</div>

A pnpm monorepo template for `@lisachandra` roblox-ts packages, modeled on the
[`rbxts`](https://github.com/lisachandra/rbxts) monorepo and the
`rbxts-game-template` tooling layer. It keeps the strict
build/lint/typecheck/test pipeline while dropping game-only machinery
(bedrock, asphalt, drillbit, darklua, LFS, submodules, and game scaffolds).

## Features

- pnpm workspace with `packages/*` (published libraries) and `test/*`
  (private jest-roblox test projects)
- `@isentinel/roblox-ts` compiler + `@isentinel/tsconfig` project references
- oxfmt + oxlint via `@isentinel/eslint-config`, commitlint + husky hooks
- tsgo (TypeScript 7 native preview) typecheck
- jest-roblox tests with a Studio CLI backend locally and Open Cloud in CI
- changesets versioning with npm publishing and a dispatch-driven release
  workflow
- pnpm patch infrastructure, including the dormant
  `rbxts-transformer-flamework` patch for future Flamework packages

## Requirements

- [mise](https://mise.jdx.dev) (pins node/pnpm/rojo/gh/jq)
- pnpm
- Git

## Getting Started

```bash
pnpm setup
```

`pnpm setup` installs with `--frozen-lockfile` and builds every workspace
package in dependency order.

For Codex agent hooks, junction your global agent config (the repo already
gitignores it):

```bash
mklink /J .agents C:\Users\PC\.agents   # Windows
ln -s ~/.agents .agents                 # Unix
```

## Commands

| Task                        | Command               |
| --------------------------- | --------------------- |
| Setup (install + build)     | `pnpm setup`          |
| Build all                   | `pnpm build`          |
| Build packages only         | `pnpm build:packages` |
| Build tests only            | `pnpm build:test`     |
| Dev (watch)                 | `pnpm dev`            |
| Lint                        | `pnpm lint:fix`       |
| Typecheck                   | `pnpm typecheck`      |
| Test (Studio CLI)           | `pnpm test`           |
| Create a changeset          | `pnpm changeset`      |
| Release (version + publish) | `pnpm release`        |

## Repository Structure

```
rbxts-package-template/
├── packages/example/     @lisachandra/example — the library package
├── test/example/         @lisachandra/test-example — its jest-roblox project
├── scripts/              build.mjs (scoped builds), hoist.mjs, prepare.mjs
├── patches/              pnpm patches (incl. dormant flamework patch)
├── .changeset/           changesets config
├── .github/              CI + release workflows, setup action, dependabot
├── .husky/               commit-msg + pre-push hooks
├── jest.shared.ts        shared jest-roblox config
├── tsconfig.json         root project references
└── pnpm-workspace.yaml   workspace globs + tooling catalog
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
`rbxtsc --type 'game'` and runs jest-roblox:

- Locally: `pnpm test` uses the `studio-cli` backend (auto-detects Studio).
- CI: the test job runs only when `ROBLOX_OPEN_CLOUD_API_KEY` is configured
  and uses the `open-cloud` backend with `ROBLOX_PLACE_ID` and
  `ROBLOX_UNIVERSE_ID` (see `.env.example`). The API key needs
  `universe-places:write` and `universe.place.luau-execution-session:write`
  scopes on a dedicated test place.

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
