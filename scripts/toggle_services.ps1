# toggle_services.ps1
#
# On-demand switch for Espanso + CopyQ: if either is running, stops both;
# otherwise starts both. Meant to be double-clicked (or pinned) so Prompt
# Ops can be turned on/off without relying on Windows autostart - neither
# tool is registered to launch at login by this repo's scripts.

param(
    [switch]$dryrun
)

Write-Host ""

$espansoCmd = Get-Command espanso -ErrorAction SilentlyContinue
$espansoRunning = $false

if ($espansoCmd) {
    & $espansoCmd.Source status *> $null
    $espansoRunning = ($LASTEXITCODE -eq 0)
}

$copyqRunning = [bool](Get-Process copyq -ErrorAction SilentlyContinue)
$copyqCmd = Get-Command copyq -ErrorAction SilentlyContinue

$turnOn = -not ($espansoRunning -or $copyqRunning)

if ($turnOn) {
    Write-Host "Turning Prompt Ops ON..."

    if ($espansoCmd) {
        if ($dryrun) {
            Write-Host "[DRYRUN] Would start Espanso"
        }
        else {
            Start-Process $espansoCmd.Source -ArgumentList "service", "start"
            Write-Host "Espanso started."
        }
    }
    else {
        Write-Host "Espanso command not found, skipping."
    }

    if ($copyqCmd) {
        if ($dryrun) {
            Write-Host "[DRYRUN] Would start CopyQ"
        }
        else {
            Start-Process $copyqCmd.Source
            Write-Host "CopyQ started."
        }
    }
    else {
        Write-Host "CopyQ command not found, skipping."
    }
}
else {
    Write-Host "Turning Prompt Ops OFF..."

    if ($espansoRunning) {
        if ($dryrun) {
            Write-Host "[DRYRUN] Would stop Espanso"
        }
        else {
            & $espansoCmd.Source service stop *> $null
            Write-Host "Espanso stopped."
        }
    }

    if ($copyqRunning) {
        if ($dryrun) {
            Write-Host "[DRYRUN] Would stop CopyQ"
        }
        else {
            Get-Process copyq -ErrorAction SilentlyContinue | Stop-Process
            Write-Host "CopyQ stopped."
        }
    }
}

Write-Host ""
Write-Host "Done."
exit 0
