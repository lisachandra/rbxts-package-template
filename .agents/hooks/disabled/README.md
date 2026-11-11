# Why these hook scripts are disabled

These three `.ps1` files are the Dirac hook entry points that used to live in
the parent `hooks/` directory. They are parked here because they cannot run
correctly, for two independent reasons:

1. **The v0.5.19 approval gate rejects them.** Before launching a workspace
   hook, Dirac fingerprints it with `realpath`. These projects reach the shared
   scripts through a symlink chain
   (`.diracrules` -> `.agents` -> `C:/Users/PC/.agents` -> `D:/Saves/User/.agents`),
   so the resolved target sits outside the workspace root and the gate throws
   `Workspace code target escapes its root`. The hook never launches, and the
   task's tool calls proceed anyway (the executor fails open).

2. **A throwing hook disables healthy ones.** Hook runners execute in parallel
   (`Promise.all` in `CombinedHookRunner`); when this file throws, the rejection
   discards the results of every other hook for the same event. Leaving it in
   place would neutralize the working replacement below.

The replacement is the global hooks at `~/.dirac/Hooks/{PreToolUse,PostToolUse,
TaskComplete}.ps1`. Global hooks skip the workspace approval gate by design
(they are machine-owned code), read this directory's `settings.json`
(`.agents/settings.json` in the project) as the single source of truth, and
dispatch to `run-hook.cmd`. Dirac's own `cli/dist` build was also fixed
(`approvedWorkspaceHookBundle` accepts symlink-resolved bundles and materializes
the whole hooks directory), so these files can be moved back and the global
shims removed once every Dirac build on this machine includes that fix (the
VS Code extension still needs `npm run compile`).

Nothing else consumes these files: Claude Code, ZCode, and Codex configs invoke
`run-hook.cmd` directly by absolute path.
