# validate_snippets.ps1
# validates all snippet YAML files and detects duplicate triggers

$repoRoot = Resolve-Path "$PSScriptRoot\.."
$snippetDir = Join-Path $repoRoot "snippets"

$files = Get-ChildItem $snippetDir -Filter "*.yml"

$allTriggers = @{}
$duplicateFound = $false

Write-Host ""
Write-Host "Validating snippet YAML files..."
Write-Host ""

foreach ($file in $files) {

    Write-Host "Checking:" $file.Name

    try {

        $content = Get-Content $file.FullName -Raw
        $yaml = $content | ConvertFrom-Yaml

        if ($null -ne $yaml["matches"]) {

            $matches = $yaml["matches"]
            $count = $matches.Count

            if ($count -eq 0) {

                Write-Host "  WARN: matches block empty" -ForegroundColor Yellow

            }
            else {

                Write-Host "  OK: $count matches detected" -ForegroundColor Green

                foreach ($match in $matches) {

                    $trigger = $match["trigger"]

                    if ($null -ne $trigger) {

                        if ($allTriggers.ContainsKey($trigger)) {

                            Write-Host "  ERROR: duplicate trigger detected -> $trigger" -ForegroundColor Red
                            Write-Host "         first defined in: $($allTriggers[$trigger])"
                            Write-Host "         again in:        $($file.Name)"

                            $duplicateFound = $true

                        }
                        else {

                            $allTriggers[$trigger] = $file.Name

                        }
                    }
                }
            }

        }
        else {

            Write-Host "  INFO: No matches block (skipped)" -ForegroundColor DarkGray

        }

    }
    catch {

        Write-Host "  ERROR: Invalid YAML" -ForegroundColor Red
        Write-Host "  $($_.Exception.Message)"
        exit 1

    }

    Write-Host ""
}

if ($duplicateFound) {

    Write-Host ""
    Write-Host "Duplicate triggers detected. Validation failed." -ForegroundColor Red
    exit 1

}

Write-Host "Validation finished."