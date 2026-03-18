# validate_yaml.ps1

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
# YAML MODULE (AUTO-INSTALL + CLOBBER SAFE)
# --------------------------------------------------

$moduleName = "powershell-yaml"

if (-not (Get-Module -ListAvailable -Name $moduleName)) {

    Write-Warning "$moduleName not found. Installing..."

    try {
        Install-Module $moduleName `
            -Force `
            -Scope CurrentUser `
            -AllowClobber `
            -ErrorAction Stop
    }
    catch {
        throw "Failed to install ${moduleName}: $($_.Exception.Message)"
    }
}

try {
    Import-Module $moduleName -ErrorAction Stop
}
catch {
    throw "Failed to import ${moduleName}: $($_.Exception.Message)"
}

# --------------------------------------------------
# LOAD FILES
# --------------------------------------------------

$files = Get-ChildItem $SnippetDir -Filter "*.yml"

if (-not $files) {
    throw "No YAML files found in $SnippetDir"
}

# --------------------------------------------------
# VALIDATION
# --------------------------------------------------

$failed = @()

foreach ($file in $files) {

    Write-Host "Checking YAML: $($file.Name)"

    $content = Get-Content $file.FullName -Raw

    # Empty file check
    if (-not $content.Trim()) {
        $failed += "$($file.Name): empty file"
        continue
    }

    try {
        $null = $content | ConvertFrom-Yaml -ErrorAction Stop
    }
    catch {
        $failed += "$($file.Name): $($_.Exception.Message)"
        continue
    }
}

# --------------------------------------------------
# RESULT
# --------------------------------------------------

if ($failed.Count -gt 0) {

    Write-Host ""
    Write-Host "YAML VALIDATION FAILED:"
    Write-Host "----------------------------------------"

    foreach ($f in $failed) {
        Write-Host " - $f"
    }

    Write-Host "----------------------------------------"
    throw "YAML validation failed"
}

# --------------------------------------------------
# SUCCESS
# --------------------------------------------------

Write-Host ""
Write-Host "All YAML files are valid"
Write-Host "Checked files: $($files.Count)"