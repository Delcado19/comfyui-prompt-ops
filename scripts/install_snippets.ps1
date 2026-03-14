param(
    [switch]$dryrun
)

Write-Host ""
Write-Host "Installing snippets..."

$root = Resolve-Path "$PSScriptRoot\.."
$snippetDir = Join-Path $root "snippets"

$espansoMatch = Join-Path $env:APPDATA "espanso\match"

if (!(Test-Path $espansoMatch)) {

    if ($dryrun) {
        Write-Host "[DRYRUN] Would create Espanso match directory"
    }
    else {
        New-Item -ItemType Directory -Path $espansoMatch | Out-Null
    }

}

$files = Get-ChildItem $snippetDir -Filter *.yml

$count = 0

foreach ($file in $files) {

    if ($dryrun) {

        Write-Host "[DRYRUN] Would copy $($file.Name)"

    }
    else {

        Copy-Item $file.FullName $espansoMatch -Force
        Write-Host "Copied $($file.Name)"

    }

    $count++

}

Write-Host ""
Write-Host "Snippets processed:" $count