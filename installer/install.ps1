# ComfyUI Prompt Ops Installer
# installer/install.ps1

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$repoRoot = Resolve-Path "$PSScriptRoot\.."

$logDir = Join-Path $repoRoot "logs"

if (!(Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}

$logFile = Join-Path $logDir "install.log"

# Must run before anything else touches pwsh-only syntax/cmdlets, and
# before any Start-Process relaunch could be added back in.
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "[FAIL] PowerShell 7 or higher is required. See https://aka.ms/powershell" -ForegroundColor Red
    exit 1
}

function Write-Log {
    param($level, $msg)
    # Timestamped line log, independent of Start-Transcript (which can miss
    # host output in some hosts and never adds per-line timestamps).
    $line = "{0} [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $level, $msg
    Add-Content -Path $logFile -Value $line -ErrorAction SilentlyContinue
}

function Write-Info {
    param($msg)
    Write-Host "[INFO] $msg" -ForegroundColor Cyan
    Write-Log "INFO" $msg
}

function Write-Warn {
    param($msg)
    Write-Host "[WARN] $msg" -ForegroundColor Yellow
    Write-Log "WARN" $msg
}

function Write-Ok {
    param($msg)
    Write-Host "[ OK ] $msg" -ForegroundColor Green
    Write-Log "OK" $msg
}

function Write-Err {
    param($msg)
    Write-Host "[FAIL] $msg" -ForegroundColor Red
    Write-Log "FAIL" $msg
}

function Update-SessionPath {
    # Merge in the latest Machine/User PATH instead of overwriting $env:Path:
    # a plain overwrite wiped out FallbackPathDir entries Install-DesktopPackage
    # had added earlier in the same run (e.g. Espanso's install dir), because
    # every subsequent package install calls this again.
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $combined = @($env:Path, $machinePath, $userPath) -join ';'
    $env:Path = ($combined -split ';' | Where-Object { $_ } | Select-Object -Unique) -join ';'
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

    # Pipe through Out-Host: winget's own console output otherwise lands in
    # PowerShell's success stream and gets bundled into this function's
    # return value (e.g. a non-empty array with $false at the end), which
    # is always truthy - silently defeating the "-not $installedWithWinget"
    # check in Install-DesktopPackage and skipping the Scoop fallback.
    & $winget.Source install `
        --id $PackageId `
        --exact `
        --source winget `
        --accept-package-agreements `
        --accept-source-agreements `
        --disable-interactivity | Out-Host

    # 0x8A15002B / -1978335189: APPINSTALLER_CLI_ERROR_UPDATE_NOT_APPLICABLE.
    # Winget found the package already installed with no newer version -
    # that's success, not a failure that should trigger the Scoop fallback.
    if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq -1978335189) {
        Write-Ok "$Name is installed via Winget"
        Update-SessionPath
        return $true
    }

    Write-Warn "Winget failed to install $Name (exit code $LASTEXITCODE). Falling back to Scoop..."
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
        [string]$ScoopBucket = "extras",
        # Known per-user install directory to add to PATH if the command
        # still can't be found afterwards. Some Winget per-user installs
        # (e.g. Espanso under %LOCALAPPDATA%\Programs) never touch the
        # registry PATH that Update-SessionPath reads from.
        [string]$FallbackPathDir = $null
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

    if ((Get-Command $CommandName -ErrorAction SilentlyContinue)) {
        return
    }

    if ($FallbackPathDir -and (Test-Path $FallbackPathDir)) {
        Write-Warn "$Name installed but not on PATH. Adding $FallbackPathDir."
        $env:Path = "$env:Path;$FallbackPathDir"

        # Winget's own PATH update (if any) only applies to *new* processes
        # started after install, so the addition above also has to be
        # persisted to the user's PATH - otherwise every later script run in
        # a fresh terminal (doctor.ps1, restart_services.ps1, ...) reports
        # $Name as missing again even though it's installed.
        $userPathEntries = @(([Environment]::GetEnvironmentVariable("Path", "User") -split ';') | Where-Object { $_ })
        if ($userPathEntries -notcontains $FallbackPathDir) {
            [Environment]::SetEnvironmentVariable("Path", (($userPathEntries + $FallbackPathDir) -join ';'), "User")
        }
    }

    if (Get-Command $CommandName -ErrorAction SilentlyContinue) {
        Write-Ok "$Name is now available"
    }
    else {
        Write-Warn "$Name was installed but is still not resolvable on PATH. You may need to restart your terminal."
    }
}

# --------------------------------------------------
# Installer
# --------------------------------------------------
# No admin elevation: nothing below needs it (snippets go to %APPDATA%,
# Espanso/CopyQ are per-user apps), and Scoop actively refuses to run
# elevated, which used to break the winget -> Scoop fallback.

try {

    Write-Host ""
    Write-Host "====================================="
    Write-Host " ComfyUI Prompt Ops Installer"
    Write-Host "====================================="
    Write-Host ""

    Start-Transcript -Path $logFile -Append | Out-Null

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
        -ScoopPackage "espanso" `
        -FallbackPathDir (Join-Path $env:LOCALAPPDATA "Programs\Espanso")

    # --------------------------------------------------
    # CopyQ
    # --------------------------------------------------

    Write-Info "Checking CopyQ..."

    Install-DesktopPackage `
        -Name "CopyQ" `
        -CommandName "copyq" `
        -WingetId "hluk.CopyQ" `
        -ScoopPackage "copyq" `
        -FallbackPathDir "$env:ProgramFiles\CopyQ"

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

    $exitCode = 0

}
catch {

    Write-Err "$_ (at $($_.InvocationInfo.ScriptName):$($_.InvocationInfo.ScriptLineNumber))"
    Write-Log "FAIL" $_.ScriptStackTrace
    Write-Host "See $logFile for the full log." -ForegroundColor Red

    $exitCode = 1
}
finally {

    # A failing Stop-Transcript (e.g. transcript never started) must not
    # mask the real error/exit code from the try/catch above.
    try { Stop-Transcript | Out-Null } catch {}
}

exit $exitCode
