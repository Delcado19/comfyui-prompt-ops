param()

Write-Host ""
Write-Host "Running snippet linter..."
Write-Host ""

$root = Resolve-Path "$PSScriptRoot\.."
$snippetDir = Join-Path $root "snippets"

$files = Get-ChildItem $snippetDir -Filter *.yml

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

    if (!$yaml.PSObject.Properties.Name.Contains("matches")) {

        Write-Host "  ERROR: Missing 'matches' block"
        $errorCount++
        continue
    }

    # -----------------------------
    # Trigger checks
    # -----------------------------

    foreach ($match in $yaml.matches) {

        if (!$match.trigger) {

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