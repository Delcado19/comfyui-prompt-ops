$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "Checking duplicate triggers..."

$root = Resolve-Path "$PSScriptRoot\.."
$snippetDir = Join-Path $root "snippets"

$moduleName = "powershell-yaml"
if (-not (Get-Module -ListAvailable -Name $moduleName)) {
    Install-Module $moduleName -Force -Scope CurrentUser -AllowClobber -ErrorAction Stop
}
Import-Module $moduleName -ErrorAction Stop

$files = Get-ChildItem $snippetDir -Filter "comfy_*.yml"

# Parsed via ConvertFrom-Yaml (not a "trigger:" regex over raw lines) so a
# quoted, multi-line, or reformatted trigger value is still caught.
$triggers = foreach ($file in $files) {
    $yaml = Get-Content $file.FullName -Raw | ConvertFrom-Yaml -ErrorAction Stop
    foreach ($match in @($yaml.matches)) {
        if ($match.trigger) { [string]$match.trigger }
    }
}

$duplicates = $triggers | Group-Object | Where-Object { $_.Count -gt 1 }

if ($duplicates) {

    Write-Host ""
    Write-Host "Duplicate triggers found:"
    Write-Host ""

    foreach ($dup in $duplicates) {
        Write-Host "$($dup.Name) ($($dup.Count) times)"
    }

    exit 1

}

Write-Host "No duplicate triggers."
