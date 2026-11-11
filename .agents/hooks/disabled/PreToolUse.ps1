# PreToolUse Hook
# Reads the hooks.PreToolUse configuration from settings.json dynamically,
# then runs the matching hook commands for the current tool.
# This keeps the enforcement logic in settings.json as the single source of truth.
#
# Semantics:
# - Blocking child exit -> cancel:true JSON + exit code 2 (Claude Code's block
#   convention). Dirac honors the JSON regardless of exit code.
# - Zero exit + output  -> advisory: cancel:false with the output as context
#   feedback (e.g. suggest-rg suggestions).

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
    # Dirac nests tool metadata under preToolUse; keep Claude-style fallback.
    $toolName = $inputObj.preToolUse.toolName
    if (-not $toolName) { $toolName = $inputObj.preToolUse.tool_name }
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
    $preToolUseHooks = $settings.hooks.PreToolUse

    if (-not $preToolUseHooks) {
        Format-HookResponse ""
        exit 0
    }

    $feedback = [System.Collections.Generic.List[string]]::new()

    # Find matchers that apply to this tool
    foreach ($entry in $preToolUseHooks) {
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

                # Strip the "# 2>nul &" echo artifact that cmd.exe emits when
                # the cross-platform run-hook.cmd polyglot starts (prompt + line).
                $text = (($output | Out-String) -split "`r?`n" | Where-Object { $_ -notmatch '^(?:.*>)?#\s*2>nul\s*&?\s*$' }) -join "`n"
                $text = $text.Trim()

                if ($exitCode -ne 0) {
                    # Blocking: any non-zero child cancels the tool.
                    if (-not $text) { $text = "Hook '$command' failed with exit code $exitCode" }
                    @{ cancel = $true; contextModification = ""; errorMessage = $text; additionalContext = ""; suppressOutput = $true } | ConvertTo-Json -Compress
                    exit 2
                } elseif ($text) {
                    # Advisory: pass-through output becomes context feedback.
                    $feedback.Add($text)
                }
            }
        }
    }

    Format-HookResponse ($feedback -join "`n`n")
    exit 0

} catch {
    Write-Error "[PreToolUse] Error: $($_.Exception.Message)"
    @{ cancel = $true; contextModification = ""; errorMessage = "PreToolUse hook error: $($_.Exception.Message)"; additionalContext = ""; suppressOutput = $true } | ConvertTo-Json -Compress
    exit 1
}
