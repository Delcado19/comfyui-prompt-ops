param()

Write-Host ""
Write-Host "Generating snippet documentation..."

$root = Resolve-Path "$PSScriptRoot\.."
$snippetDir = "$root\snippets"
$outputFile = "$root\docs\snippets.md"

$files = Get-ChildItem $snippetDir -Filter *.yml

$rows = @()

foreach ($file in $files) {

    $category = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)

    $lines = Get-Content $file.FullName

    foreach ($line in $lines) {

        if ($line -match "trigger:\s*""([^""]+)""") {

            $trigger = $matches[1]

            $rows += [PSCustomObject]@{
                Trigger = $trigger
                Category = $category
            }
        }
    }
}

$header = @"
# Espanso Snippet Registry

Automatically generated documentation of all available prompt snippets.

| Trigger | Category |
|--------|---------|
"@

$content = $rows | Sort-Object Trigger | ForEach-Object {
    "| $($_.Trigger) | $($_.Category) |"
}

$header + ($content -join "`n") | Out-File $outputFile

Write-Host "Snippet documentation generated:"
Write-Host $outputFile