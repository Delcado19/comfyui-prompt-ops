$ErrorActionPreference = "Stop"

Write-Host "[docs] Generating snippet documentation..."

# ---------------------------------------------------
# Paths
# ---------------------------------------------------

$scriptDir  = $PSScriptRoot
$repoRoot   = Split-Path -Parent $scriptDir
$snippetDir = Join-Path $repoRoot "snippets"
$docsDir    = Join-Path $repoRoot "docs"
$outFile    = Join-Path $docsDir "snippets.md"

if (-not (Test-Path $snippetDir)) {
    throw "Snippet directory not found: $snippetDir"
}

if (-not (Test-Path $docsDir)) {
    New-Item -ItemType Directory -Path $docsDir | Out-Null
}

# ---------------------------------------------------
# Collect snippet rows
# ---------------------------------------------------

$rows = [System.Collections.Generic.List[string]]::new()

Get-ChildItem $snippetDir -Filter *.yml | Sort-Object Name | ForEach-Object {

    $fileName = $_.Name
    $lines = Get-Content $_.FullName

    $trigger = $null
    $replace = $null

    $collectMultiline = $false
    $buffer = @()

    foreach ($line in $lines) {

        if ($line -match 'trigger:\s*"(.*?)"') {
            $trigger = $matches[1]
        }

        if ($line -match 'replace:\s*"(.*?)"') {
            $replace = $matches[1]

            if ($trigger) {

                $replace = $replace.Replace('|','\|')

                $rows.Add("| $trigger | $replace | $fileName |")

                $trigger = $null
                $replace = $null
            }
        }

        elseif ($line -match 'replace:\s*\|') {
            $collectMultiline = $true
            $buffer = @()
            continue
        }

        elseif ($collectMultiline) {

            if ($line -match '^\s{2,}(.*)') {
                $buffer += $matches[1]
            }
            else {

                $collectMultiline = $false

                $replace = ($buffer -join " ").Trim()

                if ($trigger) {

                    $replace = $replace.Replace('|','\|')

                    $rows.Add("| $trigger | $replace | $fileName |")

                    $trigger = $null
                }
            }
        }
    }

    # Catch multiline replace at file end
    if ($collectMultiline -and $trigger) {

        $replace = ($buffer -join " ").Trim()
        $replace = $replace.Replace('|','\|')

        $rows.Add("| $trigger | $replace | $fileName |")
    }
}

# ---------------------------------------------------
# Generate Markdown
# ---------------------------------------------------

$md = @()

$md += "# Espanso Snippet Reference"
$md += ""
$md += "Auto-generated documentation of available snippets."
$md += ""
$md += "| Trigger | Replace | File |"
$md += "|--------|---------|------|"

$md += $rows

# ---------------------------------------------------
# Write file
# ---------------------------------------------------

$md | Set-Content $outFile -Encoding utf8NoBOM

Write-Host "[docs] Snippets written:" $rows.Count
Write-Host "[docs] Output file:" $outFile
Write-Host "[docs] Documentation generation complete."