# dev.ps1

param(
    [switch]$SkipBuild,
    [switch]$VerboseMode
)

# --------------------------------------------------
# HARD FAIL
# --------------------------------------------------

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# --------------------------------------------------
# PATH SETUP
# --------------------------------------------------

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptRoot

# --------------------------------------------------
# HELPER
# --------------------------------------------------

function Run-Step {
    param (
        [string]$Name,
        [scriptblock]$Action
    )

    Write-Host ""
    Write-Host "==> $Name" -ForegroundColor Cyan

    try {
        & $Action
        Write-Host "✔ $Name passed" -ForegroundColor Green
    }
    catch {
        Write-Host "✖ $Name failed" -ForegroundColor Red
        Write-Host $_
        exit 1
    }
}

# --------------------------------------------------
# RUN PIPELINE
# --------------------------------------------------

Run-Step "Validate YAML" {
    ./validate_yaml.ps1
}

Run-Step "Validate Snippets" {
    ./validate_snippets.ps1
}

Run-Step "Check Duplicate Triggers" {
    if (Test-Path "./check_duplicate_triggers.ps1") {
        ./check_duplicate_triggers.ps1
    } else {
        Write-Warning "Duplicate check script not found, skipping"
    }
}

if (-not $SkipBuild) {
    Run-Step "Generate Prompt Builder" {
        ./generate_prompt_builder.ps1
    }
}

# --------------------------------------------------
# DONE
# --------------------------------------------------

Write-Host ""
Write-Host "ALL CHECKS PASSED" -ForegroundColor Green