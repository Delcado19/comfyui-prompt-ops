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

function Update-SessionPath {
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$machinePath;$userPath"
}

function Get-ScoopCommand {
    $scoop = Get-Command scoop -ErrorAction SilentlyContinue

    if ($scoop) {
        return $scoop.Source
    }

    $candidates = @(
        (Join-Path $env:USERPROFILE "scoop\shims\scoop.ps1"),
        (Join-Path $env:USERPROFILE "scoop\shims\scoop.cmd")
    )

    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    return $null
}

function Install-Scoop {
    $scoop = Get-ScoopCommand

    if ($scoop) {
        Write-Ok "Scoop detected"
        return $scoop
    }

    Write-Warn "Scoop not found. Installing Scoop as package-manager fallback..."

    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Invoke-RestMethod -Uri "https://get.scoop.sh" | Invoke-Expression

    $scoop = Get-ScoopCommand

    if (-not $scoop) {
        throw "Scoop installation completed, but the scoop command was not found."
    }

    Write-Ok "Scoop installed"
    Update-SessionPath
    return $scoop
}

function Install-WithWinget {
    param(
        [string]$Name,
        [string]$PackageId
    )

    $winget = Get-Command winget -ErrorAction SilentlyContinue

    if (-not $winget) {
        Write-Warn "Winget not found"
        return $false
    }

    Write-Info "Installing $Name via Winget..."

    & $winget.Source install `
        --id $PackageId `
        --exact `
        --source winget `
        --accept-package-agreements `
        --accept-source-agreements `
        --disable-interactivity

    if ($LASTEXITCODE -eq 0) {
        Write-Ok "$Name installed via Winget"
        Update-SessionPath
        return $true
    }

    Write-Warn "Winget failed to install $Name. Falling back to Scoop..."
    return $false
}

function Install-WithScoop {
    param(
        [string]$Name,
        [string]$Package,
        [string]$Bucket = "extras"
    )

    $scoop = Install-Scoop

    if ($Bucket) {
        Write-Info "Ensuring Scoop bucket '$Bucket'..."
        & $scoop bucket add $Bucket

        if ($LASTEXITCODE -ne 0) {
            Write-Warn "Scoop bucket '$Bucket' may already exist or could not be added."
        }
    }

    Write-Info "Installing $Name via Scoop..."
    & $scoop install $Package

    if ($LASTEXITCODE -ne 0) {
        throw "Scoop failed to install $Name."
    }

    Write-Ok "$Name installed via Scoop"
    Update-SessionPath
}

function Install-DesktopPackage {
    param(
        [string]$Name,
        [string]$CommandName,
        [string]$WingetId,
        [string]$ScoopPackage,
        [string]$ScoopBucket = "extras"
    )

    if (Get-Command $CommandName -ErrorAction SilentlyContinue) {
        Write-Ok "$Name detected"
        return
    }

    Write-Warn "$Name not found"

    $installedWithWinget = Install-WithWinget -Name $Name -PackageId $WingetId

    if (-not $installedWithWinget) {
        Install-WithScoop -Name $Name -Package $ScoopPackage -Bucket $ScoopBucket
    }
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
    # Package Manager Preference
    # --------------------------------------------------

    Write-Info "Checking package managers..."

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Ok "Winget detected"
    }
    else {
        Write-Warn "Winget not found. Scoop will be used as fallback when packages are missing."
    }

    # --------------------------------------------------
    # Espanso
    # --------------------------------------------------

    Write-Info "Checking Espanso..."

    Install-DesktopPackage `
        -Name "Espanso" `
        -CommandName "espanso" `
        -WingetId "Espanso.Espanso" `
        -ScoopPackage "espanso"

    # --------------------------------------------------
    # CopyQ
    # --------------------------------------------------

    Write-Info "Checking CopyQ..."

    Install-DesktopPackage `
        -Name "CopyQ" `
        -CommandName "copyq" `
        -WingetId "hluk.CopyQ" `
        -ScoopPackage "copyq"

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
