# ComfyUI Prompt Ops Installer
# installer/install.ps1

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$repoRoot = Resolve-Path "$PSScriptRoot\.."
$statusFile = Join-Path $env:TEMP "comfyui_prompt_ops_install.status"

$logDir = Join-Path $repoRoot "logs"

if (!(Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}

$logFile = Join-Path $logDir "install.log"


function Write-Info {
    param($msg)
    Write-Host "[INFO] $msg" -ForegroundColor Cyan
}

function Write-Warn {
    param($msg)
    Write-Host "[WARN] $msg" -ForegroundColor Yellow
}

function Write-Ok {
    param($msg)
    Write-Host "[ OK ] $msg" -ForegroundColor Green
}

function Write-Err {
    param($msg)
    Write-Host "[FAIL] $msg" -ForegroundColor Red
}

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# --------------------------------------------------
# Parent Process
# --------------------------------------------------

if (-not (Test-IsAdmin)) {

    Write-Warn "Administrator privileges required"
    Write-Host "Opening elevated installer..."
    Write-Host ""

    if (Test-Path $statusFile) {
        Remove-Item $statusFile -Force
    }

    Start-Process pwsh `
        -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" `
        -Verb RunAs

    Write-Host "Waiting for installer to finish..."
    Write-Host ""

    while (-not (Test-Path $statusFile)) {
        Start-Sleep -Seconds 1
    }

    $status = Get-Content $statusFile

    if ($status -eq "SUCCESS") {
        Write-Host ""
        Write-Ok "Installation completed successfully."
    }
    else {
        Write-Host ""
        Write-Err "Installation FAILED."
    }

    exit
}

# --------------------------------------------------
# Elevated Installer
# --------------------------------------------------

try {

    Write-Host ""
    Write-Host "====================================="
    Write-Host " ComfyUI Prompt Ops Installer"
    Write-Host "====================================="
    Write-Host ""

    Start-Transcript -Path $logFile -Append | Out-Null

    # --------------------------------------------------
    # PowerShell Version Check
    # --------------------------------------------------

    Write-Info "Checking PowerShell version..."

    if ($PSVersionTable.PSVersion.Major -lt 7) {
        throw "PowerShell 7 or higher is required."
    }

    Write-Ok "PowerShell $($PSVersionTable.PSVersion)"

    # --------------------------------------------------
    # Chocolatey Check / Install
    # --------------------------------------------------

    Write-Info "Checking Chocolatey..."

    $choco = Get-Command choco -ErrorAction SilentlyContinue

    if (-not $choco) {

        Write-Warn "Chocolatey not found. Installing..."

        Set-ExecutionPolicy Bypass -Scope Process -Force

        [System.Net.ServicePointManager]::SecurityProtocol =
            [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

        Invoke-Expression (
            (New-Object System.Net.WebClient).DownloadString(
                "https://community.chocolatey.org/install.ps1"
            )
        )

        Write-Ok "Chocolatey installed"
    }
    else {
        Write-Ok "Chocolatey detected"
    }

    # --------------------------------------------------
    # Espanso
    # --------------------------------------------------

    Write-Info "Checking Espanso..."

    $espanso = Get-Command espanso -ErrorAction SilentlyContinue

    if (-not $espanso) {
        Write-Warn "Installing Espanso via Chocolatey..."
        choco install espanso -y
    }
    else {
        Write-Ok "Espanso detected"
    }

    # --------------------------------------------------
    # CopyQ
    # --------------------------------------------------

    Write-Info "Checking CopyQ..."

    $copyq = Get-Command copyq -ErrorAction SilentlyContinue

    if (-not $copyq) {
        Write-Warn "Installing CopyQ via Chocolatey..."
        choco install copyq -y
    }
    else {
        Write-Ok "CopyQ detected"
    }

    # --------------------------------------------------
    # YAML support
    # --------------------------------------------------

    Write-Info "Checking YAML support..."

    $yamlCommand = Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue

    if (-not $yamlCommand) {

        Write-Warn "Installing powershell-yaml module..."

        Install-Module powershell-yaml `
            -Scope CurrentUser `
            -Force `
            -AllowClobber

        Write-Ok "powershell-yaml installed"

    }
    else {

        Write-Ok "YAML support detected"

    }

    # --------------------------------------------------
    # Install Snippets
    # --------------------------------------------------

    Write-Info "Installing snippets..."

    $snippetScript = Join-Path $repoRoot "scripts\install_snippets.ps1"

    if (-not (Test-Path $snippetScript)) {
        throw "install_snippets.ps1 not found"
    }

    & $snippetScript

    Write-Ok "Snippets installed"

    # --------------------------------------------------
    # Generate Docs
    # --------------------------------------------------

    Write-Info "Generating snippet documentation..."

    $docScript = Join-Path $repoRoot "scripts\generate_snippet_docs.ps1"

    if (-not (Test-Path $docScript)) {
        throw "generate_snippet_docs.ps1 not found"
    }

    & $docScript

    Write-Ok "Snippet docs generated"

    # --------------------------------------------------
    # Restart Services
    # --------------------------------------------------

    Write-Info "Restarting services..."

    $serviceScript = Join-Path $repoRoot "scripts\restart_services.ps1"

    if (-not (Test-Path $serviceScript)) {
        throw "restart_services.ps1 not found"
    }

    & $serviceScript

    Write-Ok "Services restarted"

    # --------------------------------------------------
    # Done
    # --------------------------------------------------

    Write-Host ""
    Write-Ok "Setup completed"
    Write-Host ""

    "SUCCESS" | Out-File $statusFile -Encoding ascii

}
catch {

    Write-Err $_

    "FAILED" | Out-File $statusFile -Encoding ascii
}
finally {

    Stop-Transcript | Out-Null
}