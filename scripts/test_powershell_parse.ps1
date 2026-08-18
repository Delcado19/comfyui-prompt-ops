# test_powershell_parse.ps1

# --------------------------------------------------
# HARD FAIL SETTINGS
# --------------------------------------------------

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# --------------------------------------------------
# PATH SETUP
# --------------------------------------------------

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path "$ScriptRoot/.."

# --------------------------------------------------
# COLLECT SCRIPTS
# --------------------------------------------------

# [\\/] matches both separators - Windows gives FullName with "\", Linux/macOS with "/".
$files = Get-ChildItem $RepoRoot -Recurse -Filter "*.ps1" |
    Where-Object {
        $_.FullName -notmatch "[\\/]\.git[\\/]" -and
        $_.FullName -notmatch "[\\/]node_modules[\\/]"
    } |
    Sort-Object FullName

if (-not $files) {
    throw "No PowerShell scripts found."
}

# --------------------------------------------------
# PARSE VALIDATION
# --------------------------------------------------

$failed = @()

foreach ($file in $files) {
    Write-Host "Parsing PowerShell: $($file.FullName.Substring($RepoRoot.Path.Length + 1))"

    $tokens = $null
    $errors = $null

    [System.Management.Automation.Language.Parser]::ParseFile(
        $file.FullName,
        [ref]$tokens,
        [ref]$errors
    ) | Out-Null

    foreach ($errorItem in $errors) {
        $failed += "$($file.FullName): line $($errorItem.Extent.StartLineNumber), column $($errorItem.Extent.StartColumnNumber): $($errorItem.Message)"
    }
}

# --------------------------------------------------
# RESULT
# --------------------------------------------------

if ($failed.Count -gt 0) {
    Write-Host ""
    Write-Host "POWERSHELL PARSE VALIDATION FAILED:"
    Write-Host "----------------------------------------"

    foreach ($failure in $failed) {
        Write-Host " - $failure"
    }

    Write-Host "----------------------------------------"
    throw "PowerShell parse validation failed"
}

Write-Host ""
Write-Host "All PowerShell scripts parse successfully"
Write-Host "Checked files: $($files.Count)"
