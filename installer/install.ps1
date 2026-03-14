param(
    [switch]$dryrun
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "================================="
Write-Host " ComfyUI Prompt Ops Installer"
Write-Host "================================="
Write-Host ""

if ($dryrun) {
    Write-Host "MODE: DRY RUN"
    Write-Host ""
}

# Repo Root bestimmen
$root = Resolve-Path "$PSScriptRoot\.."

# Script Pfade
$checkEnv = "$root\scripts\check_environment.ps1"
$installDeps = "$root\scripts\install_dependencies.ps1"
$validateConfig = "$root\scripts\validate_config.ps1"
$installSnippets = "$root\scripts\install_snippets.ps1"
$restartServices = "$root\scripts\restart_services.ps1"

Write-Host "Repo Root:"
Write-Host $root
Write-Host ""

# Schritt 1 – Environment prüfen
Write-Host "Step 1: Environment Check"
& $checkEnv -dryrun:$dryrun

# Schritt 2 – Dependencies installieren
Write-Host ""
Write-Host "Step 2: Dependency Installation"
& $installDeps -dryrun:$dryrun

# Schritt 3 – Espanso Config prüfen
Write-Host ""
Write-Host "Step 3: Config Validation"
& $validateConfig -dryrun:$dryrun

# Schritt 4 – Snippets installieren
Write-Host ""
Write-Host "Step 4: Snippet Installation"
& $installSnippets -dryrun:$dryrun

# Schritt 5 – Services starten
Write-Host ""
Write-Host "Step 5: Service Restart"
& $restartServices -dryrun:$dryrun

Write-Host ""
Write-Host "================================="
Write-Host " Setup completed successfully"
Write-Host "================================="
Write-Host ""