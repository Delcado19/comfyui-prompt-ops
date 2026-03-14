param(
    [switch]$dryrun
)


# --------------------------------
# AUTO ADMIN ELEVATION
# --------------------------------

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)

$isAdmin = $principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

if (-not $isAdmin -and -not $dryrun) {

    Write-Host ""
    Write-Host "Administrator privileges required."
    Write-Host "Restarting installer with elevation..."
    Write-Host ""

    $script = $MyInvocation.MyCommand.Path

    $args = @()
    if ($dryrun) { $args += "-dryrun" }

    Start-Process pwsh `
        -ArgumentList "-ExecutionPolicy Bypass -File `"$script`" $args" `
        -Verb RunAs

    exit
}


$installerVersion = "1.1.0"

$root = (Resolve-Path "$PSScriptRoot\..").Path
$restartServices = Join-Path $root "scripts\restart_services.ps1"
$installSnippets = Join-Path $root "scripts\install_snippets.ps1"
$snippetDir = Join-Path $root "snippets"

Start-Transcript -Path "$root\install.log" -Append | Out-Null

Write-Host ""
Write-Host "================================="
Write-Host " ComfyUI Prompt Ops Installer"
Write-Host " Version $installerVersion"
Write-Host "================================="
Write-Host ""

if ($dryrun) {
    Write-Host "MODE: DRY RUN (no changes will be made)"
    Write-Host ""
}

# --------------------------------
# ADMIN CHECK
# --------------------------------

Write-Host "Checking administrator privileges..."

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)

$isAdmin = $principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

if (!$isAdmin -and !$dryrun) {

    Write-Host ""
    Write-Host "ERROR: Installer must be run as Administrator."
    Write-Host ""
    Write-Host "Please restart PowerShell with:"
    Write-Host "Run as Administrator"

    Stop-Transcript | Out-Null
    exit 1
}

if (!$isAdmin -and $dryrun) {
    Write-Host "WARNING: Not running as Administrator."
    Write-Host "DryRun will continue."
}

# --------------------------------
# POWERSHELL VERSION
# --------------------------------

Write-Host ""
Write-Host "Checking PowerShell version..."

$psVersion = $PSVersionTable.PSVersion.Major

if ($psVersion -lt 7) {

    Write-Host ""
    Write-Host "ERROR: PowerShell 7 or higher required."
    Stop-Transcript | Out-Null
    exit 1
}

Write-Host "PowerShell version OK:" $PSVersionTable.PSVersion

# --------------------------------
# CHOCOLATEY CHECK
# --------------------------------

Write-Host ""
Write-Host "Checking Chocolatey..."

$choco = Get-Command choco -ErrorAction SilentlyContinue

if (!$choco) {

    Write-Host "ERROR: Chocolatey not installed."
    Write-Host "Install from https://chocolatey.org/install"

    Stop-Transcript | Out-Null
    exit 1
}

Write-Host "Chocolatey found."

# --------------------------------
# REQUIRED TOOLS
# --------------------------------

Write-Host ""
Write-Host "Checking required tools..."

function Install-ChocoPackage {
    param($name)

    if ($dryrun) {
        Write-Host "[DRYRUN] Would install $name via Chocolatey"
        return
    }

    choco install $name -y

    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Failed to install $name"
        Stop-Transcript | Out-Null
        exit 1
    }
}

$espanso = Get-Command espanso -ErrorAction SilentlyContinue
$copyq = Get-Command copyq -ErrorAction SilentlyContinue

if (!$espanso) {
    Write-Host "Espanso not found."
    Install-ChocoPackage "espanso"
}
else {
    Write-Host "Espanso found."
}

if (!$copyq) {
    Write-Host "CopyQ not found."
    Install-ChocoPackage "copyq"
}
else {
    Write-Host "CopyQ found."
}

# --------------------------------
# ESPANSO CONFIG
# --------------------------------

Write-Host ""
Write-Host "Checking Espanso config..."

$espansoConfig = Join-Path $env:APPDATA "espanso"

if (!(Test-Path $espansoConfig)) {

    if ($dryrun) {
        Write-Host "[DRYRUN] Would create Espanso config directory"
    }
    else {
        New-Item -ItemType Directory -Path $espansoConfig | Out-Null
        Write-Host "Espanso config directory created."
    }

}
else {
    Write-Host "Espanso config directory found."
}

# --------------------------------
# SNIPPET DIRECTORY
# --------------------------------

Write-Host ""
Write-Host "Checking snippet directory..."

if (!(Test-Path $snippetDir)) {

    Write-Host ""
    Write-Host "ERROR: Snippet directory missing:"
    Write-Host $snippetDir

    Stop-Transcript | Out-Null
    exit 1
}

$snippetFiles = Get-ChildItem $snippetDir -Filter *.yml

if ($snippetFiles.Count -eq 0) {
    Write-Host "WARNING: No snippet files found."
}
else {
    Write-Host "Snippet directory found. Files:" $snippetFiles.Count
}

# --------------------------------
# SCRIPT DEPENDENCIES
# --------------------------------

if (!(Test-Path $installSnippets)) {

    Write-Host "ERROR: Missing script:"
    Write-Host $installSnippets

    Stop-Transcript | Out-Null
    exit 1
}

if (!(Test-Path $restartServices)) {

    Write-Host "ERROR: Missing script:"
    Write-Host $restartServices

    Stop-Transcript | Out-Null
    exit 1
}

# --------------------------------
# INSTALL STEPS
# --------------------------------

Write-Host ""
Write-Host "Repo Root:"
Write-Host $root

Write-Host ""
Write-Host "Step 1: Environment Check"

Write-Host ""
Write-Host "Step 2: Dependency Installation"

Write-Host ""
Write-Host "Step 3: Config Validation"

Write-Host ""
Write-Host "Step 4: Snippet Installation"

& $installSnippets -dryrun:$dryrun

Write-Host ""
Write-Host "Step 5: Service Restart"

& $restartServices -dryrun:$dryrun

Write-Host ""
Write-Host "Reloading Espanso..."

if ($dryrun) {
    Write-Host "[DRYRUN] Would reload Espanso"
}
else {

    try {
        espanso restart
    }
    catch {
        Write-Host "Espanso restart failed, attempting start..."
        espanso start
    }

}

Write-Host ""
Write-Host "================================="
Write-Host " Setup completed"
Write-Host "================================="

Stop-Transcript | Out-Null