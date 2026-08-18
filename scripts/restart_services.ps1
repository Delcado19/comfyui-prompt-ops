param(
    [switch]$dryrun
)

Write-Host ""
Write-Host "Restarting services..."

$copyq = Get-Process copyq -ErrorAction SilentlyContinue

# Espanso
#
# Espanso's daemon process is named "espansod", not "espanso" (the espanso
# command is just the CLI front-end), so a Get-Process espanso check never
# matches - ask espanso itself via its status exit code (0 = running)
# instead. Starting it also needs the 'service start' subcommand: a bare
# invocation only prints usage help and exits in Espanso 2.x.

$espansoCmd = Get-Command espanso -ErrorAction SilentlyContinue
$espansoRunning = $false

if ($espansoCmd) {
    & $espansoCmd.Source status *> $null
    $espansoRunning = ($LASTEXITCODE -eq 0)
}

if (!$espansoRunning) {

    Write-Host "Espanso not running."

    if ($dryrun) {
        Write-Host "[DRYRUN] Would start Espanso"
    }
    elseif ($espansoCmd) {
        Start-Process $espansoCmd.Source -ArgumentList "service", "start"
    }
    else {
        Write-Host "Espanso command not found, skipping."
    }

}
else {
    Write-Host "Espanso already running."
}

# CopyQ

$copyqCmd = Get-Command copyq -ErrorAction SilentlyContinue

if (!$copyq) {

    Write-Host "CopyQ not running."

    if ($dryrun) {
        Write-Host "[DRYRUN] Would start CopyQ"
    }
    elseif ($copyqCmd) {
        Start-Process $copyqCmd.Source
    }
    else {
        Write-Host "CopyQ command not found, skipping."
    }

}
else {
    Write-Host "CopyQ already running."
}

Write-Host ""
Write-Host "Service check completed."

# Without this, the script's own exit code falls through to whatever the
# last native call set $LASTEXITCODE to (e.g. a nonzero "espanso status"
# when Espanso wasn't running yet) even though the script itself succeeded.
exit 0