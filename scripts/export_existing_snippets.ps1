param()

Write-Host ""
Write-Host "Exporting existing Espanso snippets..."

$repoRoot = (Resolve-Path "$PSScriptRoot\..").Path
$repoSnippetDir = Join-Path $repoRoot "snippets"

$espansoDir = Join-Path $env:APPDATA "espanso\match"

if (!(Test-Path $espansoDir)) {

    Write-Host "ERROR: Espanso match directory not found."
    exit 1

}

if (!(Test-Path $repoSnippetDir)) {

    New-Item -ItemType Directory -Path $repoSnippetDir | Out-Null

}

$files = Get-ChildItem $espansoDir -Filter *.yml

$count = 0

foreach ($file in $files) {

    $dest = Join-Path $repoSnippetDir $file.Name

    Copy-Item $file.FullName $dest -Force

    Write-Host "Copied:" $file.Name

    $count++

}

Write-Host ""
Write-Host "Export completed."
Write-Host "Files exported:" $count