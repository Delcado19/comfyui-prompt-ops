param(
    [switch]$dryrun
)

Write-Host ""
Write-Host "Restarting services..."

$espanso = Get-Process espanso -ErrorAction SilentlyContinue
$copyq = Get-Process copyq -ErrorAction SilentlyContinue

# Espanso

if (!$espanso) {

    Write-Host "Espanso not running."

    if ($dryrun) {
        Write-Host "[DRYRUN] Would start Espanso"
    }
    else {
        Start-Process espanso
    }

}
else {
    Write-Host "Espanso already running."
}

# CopyQ

if (!$copyq) {

    Write-Host "CopyQ not running."

    if ($dryrun) {
        Write-Host "[DRYRUN] Would start CopyQ"
    }
    else {
        Start-Process copyq
    }

}
else {
    Write-Host "CopyQ already running."
}

Write-Host ""
Write-Host "Service check completed."