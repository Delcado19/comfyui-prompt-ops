Write-Host ""
Write-Host "Checking duplicate triggers..."

$root = Resolve-Path "$PSScriptRoot\.."
$snippetDir = Join-Path $root "snippets"

$files = Get-ChildItem $snippetDir -Filter *.yml

$triggers = @()

foreach ($file in $files) {

    $lines = Get-Content $file.FullName

    foreach ($line in $lines) {

        if ($line -match 'trigger:\s*"([^"]+)"') {

            $triggers += $matches[1]

        }

    }

}

$duplicates = $triggers | Group-Object | Where-Object { $_.Count -gt 1 }

if ($duplicates) {

    Write-Host ""
    Write-Host "Duplicate triggers found:"
    Write-Host ""

    foreach ($dup in $duplicates) {

        Write-Host $dup.Name " (" $dup.Count "times )"

    }

    exit 1

}

Write-Host "No duplicate triggers."