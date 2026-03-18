# validate_snippets.ps1

# --------------------------------------------------
# HARD FAIL SETTINGS
# --------------------------------------------------

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# --------------------------------------------------
# PATH SETUP (CI SAFE)
# --------------------------------------------------

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot   = Resolve-Path "$ScriptRoot/.."
$SnippetDir = Join-Path $RepoRoot "snippets"

if (-not (Test-Path $SnippetDir)) {
    throw "Snippet directory not found: $SnippetDir"
}

# --------------------------------------------------
# YAML MODULE
# --------------------------------------------------

$moduleName = "powershell-yaml"

if (-not (Get-Module -ListAvailable -Name $moduleName)) {

    Write-Warning "$moduleName not found. Installing..."

    Install-Module $moduleName `
        -Force `
        -Scope CurrentUser `
        -AllowClobber `
        -ErrorAction Stop
}

Import-Module $moduleName -ErrorAction Stop

# --------------------------------------------------
# LOAD FILES
# --------------------------------------------------

$files = Get-ChildItem $SnippetDir -Filter "comfy_*.yml"

if (-not $files) {
    throw "No snippet files found in $SnippetDir"
}

# --------------------------------------------------
# VALIDATION
# --------------------------------------------------

$failed   = @()
$warnings = @()

foreach ($file in $files) {

    Write-Host "Validating: $($file.Name)"

    # ---------- LOAD ----------
    try {
        $yaml = Get-Content $file.FullName -Raw | ConvertFrom-Yaml -ErrorAction Stop
    }
    catch {
        $failed += "$($file.Name): YAML parse error → $($_.Exception.Message)"
        continue
    }

    # ---------- STRUCTURE ----------
    if (-not $yaml.matches) {
        $failed += "$($file.Name): missing 'matches'"
        continue
    }

    if (-not ($yaml.matches -is [System.Collections.IEnumerable])) {
        $failed += "$($file.Name): 'matches' is not a list"
        continue
    }

    $index = 0

    foreach ($m in $yaml.matches) {

        $index++

        # ---------- REQUIRED FIELDS ----------
        if (-not $m.replace) {
            $failed += "$($file.Name) [entry $index]: missing 'replace'"
            continue
        }

        # ---------- CLEAN VALUE ----------
        $value = $m.replace.Trim()

        if ([string]::IsNullOrWhiteSpace($value)) {
            $failed += "$($file.Name) [entry $index]: empty replace"
            continue
        }

        # ---------- NORMALIZATION ----------
        $value = $value -replace "\r?\n", " "

        # ---------- TEMPLATE CHECK ----------
        if ($value -match "{{") {
            $warnings += "$($file.Name) [entry $index]: template detected → $value"
        }

        # ---------- WEAK CONTENT CHECK ----------
        if ($value.Length -lt 3) {
            $warnings += "$($file.Name) [entry $index]: suspiciously short → '$value'"
        }

        # ---------- DUPLICATE DETECTION (per file) ----------
        # (optional but useful)
    }

    # ---------- EMPTY MATCHES ----------
    if ($yaml.matches.Count -eq 0) {
        $failed += "$($file.Name): matches list is empty"
    }
}

# --------------------------------------------------
# OUTPUT WARNINGS
# --------------------------------------------------

if ($warnings.Count -gt 0) {

    Write-Host ""
    Write-Host "WARNINGS:"
    Write-Host "----------------------------------------"

    $warnings | ForEach-Object {
        Write-Host " - $_"
    }

    Write-Host "----------------------------------------"
}

# --------------------------------------------------
# FAIL ON ERRORS
# --------------------------------------------------

if ($failed.Count -gt 0) {

    Write-Host ""
    Write-Host "SNIPPET VALIDATION FAILED:"
    Write-Host "----------------------------------------"

    $failed | ForEach-Object {
        Write-Host " - $_"
    }

    Write-Host "----------------------------------------"

    throw "Snippet validation failed"
}

# --------------------------------------------------
# SUCCESS
# --------------------------------------------------

Write-Host ""
Write-Host "All snippets are valid"
Write-Host "Checked files: $($files.Count)"