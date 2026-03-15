$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot  = Split-Path -Parent $scriptDir

$snippetDir = Join-Path $repoRoot "snippets"
$docsDir    = Join-Path $repoRoot "docs"
$outFile    = Join-Path $docsDir "snippets.md"

if (!(Test-Path $docsDir)) {
    New-Item -ItemType Directory -Path $docsDir | Out-Null
}

$rows = @()

Get-ChildItem $snippetDir -Filter *.yml | ForEach-Object {

    $fileName = $_.Name
    $lines = Get-Content $_.FullName

    $trigger = $null
    $replace = ""
    $collectMultiline = $false

    foreach ($line in $lines) {

        if ($line -match 'trigger:\s*"?(.+?)"?\s*$') {
            $trigger = $Matches[1]
            $replace = ""
            $collectMultiline = $false
            continue
        }

        if ($line -match 'replace:\s*"(.*)"\s*$') {
            $replace = $Matches[1].Trim()

            if ($trigger) {
                $rows += "| $trigger | $replace | $fileName |"
                $trigger = $null
                $replace = ""
            }

            continue
        }

        if ($line -match 'replace:\s*\|') {
            $replace = ""
            $collectMultiline = $true
            continue
        }

        if ($collectMultiline) {

            if ($line -match '^\s+(.+)$') {
                $replace += " " + $Matches[1].Trim()
                continue
            }
            else {
                $collectMultiline = $false

                if ($trigger) {
                    $rows += "| $trigger | $($replace.Trim()) | $fileName |"
                    $trigger = $null
                    $replace = ""
                }
            }
        }
    }

    if ($collectMultiline -and $trigger) {
        $rows += "| $trigger | $($replace.Trim()) | $fileName |"
        $trigger = $null
        $replace = ""
        $collectMultiline = $false
    }
}

$md = @()
$md += "| Trigger | Replace | File |"
$md += "|--------|---------|------|"

$md += $rows

$md | Set-Content $outFile -Encoding UTF8

Write-Host "Snippets written:" $rows.Count
Write-Host "Output file:" $outFile