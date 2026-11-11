# PostToolUse Hook
# Reads the hooks.PostToolUse configuration from settings.json dynamically,
# then runs the matching hook commands for the current tool.
# This keeps the enforcement logic in settings.json as the single source of truth.
#
# PostToolUse is advisory (Claude Code PostToolUse semantics): findings are
# returned as context feedback for the agent, but the tool that triggered the
# hook is NEVER cancelled or failed by this script.

function Format-HookResponse {
    param([string]$Context)

    $response = @{
        cancel              = $false
        contextModification = $Context
        errorMessage        = ""
        additionalContext   = $Context
        suppressOutput      = $true
    }
    return $response | ConvertTo-Json -Compress
}

try {
    # Read JSON from stdin (how Dirac and Claude Code invoke hooks)
    $rawInput = [Console]::In.ReadToEnd()
    if (-not $rawInput) {
        Format-HookResponse ""
        exit 0
    }

    $inputObj = $rawInput | ConvertFrom-Json
    # Dirac nests tool metadata under postToolUse; Claude Code nests it under
    # postToolUse too but uses snake_case (tool_name/tool_input).
    $toolName = $inputObj.postToolUse.toolName
    if (-not $toolName) { $toolName = $inputObj.postToolUse.tool_name }
    if (-not $toolName) { $toolName = $inputObj.tool_name }

    # Locate settings.json relative to this script's directory
    # Script is in .agents/hooks/ -- settings.json is in .agents/
    $hookDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $settingsPath = Join-Path (Split-Path -Parent $hookDir) "settings.json"

    if (-not (Test-Path $settingsPath)) {
        Format-HookResponse ""
        exit 0
    }

    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
    $postToolUseHooks = $settings.hooks.PostToolUse

    if (-not $postToolUseHooks) {
        Format-HookResponse ""
        exit 0
    }

    $feedback = [System.Collections.Generic.List[string]]::new()

    # Find matchers that apply to this tool
    foreach ($entry in $postToolUseHooks) {
        $matcher = $entry.matcher
        if ($toolName -match $matcher) {
            foreach ($hook in $entry.hooks) {
                if ($hook.type -ne "command") { continue }

                $command = $hook.command
                $parts = $command -split ' ', 2
                $runner = $parts[0]
                $scriptArgs = if ($parts.Count -gt 1) { $parts[1] } else { "" }

                # Resolve .agents/... relative to the agents dir (parent of hooks/), not hooks/.
                # settings commands look like ".agents/hooks/run-hook.cmd ...";
                # using $hookDir would produce ".../hooks/hooks/...".
                $agentsDir = (Split-Path -Parent $hookDir).Replace('\', '/')
                $resolvedRunner = $runner -replace '^\.agents/', ($agentsDir + '/')

                $output = $rawInput | & $resolvedRunner $scriptArgs 2>&1
                $exitCode = $LASTEXITCODE

                # Advisory only: lint findings (or hook failures) become context
                # feedback; a non-zero exit never cancels the triggering tool.
                # Strip the "# 2>nul &" echo artifact that cmd.exe emits when the
                # cross-platform run-hook.cmd polyglot starts (prompt + line).
                $text = (($output | Out-String) -split "`r?`n" | Where-Object { $_ -notmatch '^(?:.*>)?#\s*2>nul\s*&?\s*$' }) -join "`n"
                $text = $text.Trim()
                if ($exitCode -ne 0) {
                    if ($text) {
                        $feedback.Add("Hook '$command' exited with code $exitCode.`n$text")
                    } else {
                        $feedback.Add("Hook '$command' exited with code $exitCode.")
                    }
                } elseif ($text) {
                    $feedback.Add($text)
                }
            }
        }
    }

    Format-HookResponse ($feedback -join "`n`n")
    exit 0

} catch {
    # Even an unexpected failure must not cancel the edit; surface it as feedback.
    Format-HookResponse "PostToolUse hook error: $($_.Exception.Message)"
    exit 0
}