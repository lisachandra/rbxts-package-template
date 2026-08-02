# 2>nul & @echo off & goto batch

# ZCode loads configuration hooks from user scope, so gate execution by
# workspace: only run when the current project's `.agents` directory contains
# this shared hook (i.e. the project links the shared agents directory).
CURRENT_PROJECT="${ZCODE_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-}}"
if [[ -z "${CURRENT_PROJECT}" ]]; then
    exit 0
fi

PROJECT_HOOK="${CURRENT_PROJECT}/.agents/hooks/run-project-hook.cmd"
if [[ ! -f "${PROJECT_HOOK}" ]]; then
    exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
exec bash "${SCRIPT_DIR}/run-hook.cmd" "$@"

:batch
setlocal EnableDelayedExpansion

if "%~1"=="" (
    echo run-project-hook.cmd: missing script name >&2
    exit /b 1
)

set "CURRENT_PROJECT=%ZCODE_PROJECT_DIR%"
if not defined CURRENT_PROJECT set "CURRENT_PROJECT=%CLAUDE_PROJECT_DIR%"
set "CURRENT_PROJECT=%CURRENT_PROJECT:/=\%"

if "%CURRENT_PROJECT%"=="" exit /b 0
if not exist "%CURRENT_PROJECT%\.agents\hooks\run-project-hook.cmd" exit /b 0

call "%~dp0run-hook.cmd" %*
exit /b !ERRORLEVEL!