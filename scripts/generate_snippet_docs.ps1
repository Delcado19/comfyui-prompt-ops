# generate_snippet_docs.ps1

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

Write-Host "[docs] Generating snippet documentation..."

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path "$ScriptRoot/.."
$SnippetDir = Join-Path $RepoRoot "snippets"
$DocsDir = Join-Path $RepoRoot "docs"
$OutputFile = Join-Path $DocsDir "snippets.md"

$moduleName = "powershell-yaml"

if (-not (Get-Module -ListAvailable -Name $moduleName)) {
    Install-Module $moduleName -Force -Scope CurrentUser -AllowClobber -ErrorAction Stop
}

Import-Module $moduleName -ErrorAction Stop

if (-not (Test-Path $SnippetDir)) {
    throw "Snippet directory not found: $SnippetDir"
}

if (-not (Test-Path $DocsDir)) {
    New-Item -ItemType Directory -Path $DocsDir | Out-Null
}

function Escape-MarkdownCell {
    param([string]$Value)
    return (($Value -replace "\r?\n", " ").Trim()).Replace("|", "\|")
}

$rows = [System.Collections.Generic.List[string]]::new()

Get-ChildItem $SnippetDir -Filter "*.yml" | Sort-Object Name | ForEach-Object {
    $fileName = $_.Name
    $yaml = Get-Content $_.FullName -Raw | ConvertFrom-Yaml -ErrorAction Stop

    if (-not $yaml.ContainsKey("matches")) {
        return
    }

    $matches = @($yaml["matches"])

    foreach ($match in $matches) {
        $trigger = [string]$match["trigger"]
        $replace = [string]$match["replace"]

        if ([string]::IsNullOrWhiteSpace($trigger) -or [string]::IsNullOrWhiteSpace($replace)) {
            continue
        }

        $rows.Add("| $(Escape-MarkdownCell $trigger) | $(Escape-MarkdownCell $replace) | $fileName |")
    }
}

$md = @(
    "# Espanso Snippet Reference",
    "",
    "Auto-generated documentation of available snippets.",
    "",
    "| Trigger | Replace | File |",
    "|--------|---------|------|"
)

$md += $rows

$md | Set-Content $OutputFile -Encoding utf8NoBOM

Write-Host "[docs] Snippets written:" $rows.Count
Write-Host "[docs] Output file:" $OutputFile
Write-Host "[docs] Documentation generation complete."
