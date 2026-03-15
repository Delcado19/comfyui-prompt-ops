param()

Write-Host ""
Write-Host "Running snippet linter..."
Write-Host ""

$root = Resolve-Path "$PSScriptRoot\.."
$snippetDir = Join-Path $root "snippets"

# Ignore espanso config file
$files = Get-ChildItem $snippetDir -Filter *.yml |
         Where-Object { $_.Name -ne "default.yml" }

$triggerMap = @{}
$errorCount = 0

foreach ($file in $files) {

    Write-Host "Checking:" $file.Name

    $content = Get-Content $file.FullName -Raw

    # -----------------------------
    # Empty file check
    # -----------------------------

    if ([string]::IsNullOrWhiteSpace($content)) {

        Write-Host "  ERROR: Empty file"
        $errorCount++
        continue
    }

    # -----------------------------
    # YAML validation
    # -----------------------------

    try {

        $yaml = $content | ConvertFrom-Yaml

    }
    catch {

        Write-Host "  ERROR: Invalid YAML"
        $errorCount++
        continue
    }

    # -----------------------------
    # matches block check
    # -----------------------------

    $matchesBlock = $null

    if ($yaml -is [System.Collections.IDictionary]) {

        if ($yaml.Contains("matches")) {
            $matchesBlock = $yaml["matches"]
        }

    }
    else {

        if ($yaml.PSObject.Properties["matches"]) {
            $matchesBlock = $yaml.matches
        }

    }

    if (-not $matchesBlock) {

        Write-Host "  INFO: No matches block (skipped)"
        Write-Host ""
        continue

    }

    # -----------------------------
    # Trigger checks
    # -----------------------------

    foreach ($match in $matchesBlock) {

        if (-not $match.trigger) {

            Write-Host "  ERROR: Match without trigger"
            $errorCount++
            continue
        }

        $trigger = $match.trigger

        if ($triggerMap.ContainsKey($trigger)) {

            Write-Host "  ERROR: Duplicate trigger: $trigger"
            Write-Host "    first:  $($triggerMap[$trigger])"
            Write-Host "    second: $($file.Name)"

            $errorCount++

        }
        else {

            $triggerMap[$trigger] = $file.Name

        }

    }

    Write-Host "  OK"
    Write-Host ""

}

Write-Host "---------------------------------"
Write-Host "Linter summary"
Write-Host "---------------------------------"

Write-Host "Files checked:" $files.Count
Write-Host "Triggers found:" $triggerMap.Count
Write-Host "Errors:" $errorCount
Write-Host ""

if ($errorCount -gt 0) {

    Write-Host "Linter FAILED"
    exit 1

}
else {

    Write-Host "Linter PASSED"

}