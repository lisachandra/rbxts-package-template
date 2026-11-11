# TaskComplete Hook
#
# Creates the Sandcastle completion marker automatically when a Sandcastle
# phase agent finishes. Sandcastle sets SANDCASTLE_MARKER_COMPLETED, so regular
# interactive Dirac tasks are never affected.
#
# TaskComplete runs after the completion is committed, so the marker exists by
# the time the Sandcastle wrapper verifies it. The hook does not need (and must
# not rely on) another agent turn to create the file.

try {
    $rawInput = [Console]::In.ReadToEnd()
    if ($rawInput) {
        $null = $rawInput | ConvertFrom-Json
    }

    $marker = $env:SANDCASTLE_MARKER_COMPLETED
    if ($marker) {
        $markerDir = Split-Path -Parent $marker
        New-Item -ItemType Directory -Force -Path $markerDir | Out-Null
        New-Item -ItemType File -Force -Path $marker | Out-Null
    }
} catch {
    # Marker bookkeeping must never fail the already-completed task.
}

@{ cancel = $false; contextModification = ""; errorMessage = "" } | ConvertTo-Json -Compress
