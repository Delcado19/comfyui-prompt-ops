param()

Write-Host ""
Write-Host "================================="
Write-Host " ComfyUI Prompt Ops Doctor"
Write-Host "================================="
Write-Host ""

$root = (Resolve-Path "$PSScriptRoot\..").Path
$snippetDir = Join-Path $root "snippets"
$espansoDir = Join-Path $env:APPDATA "espanso"
$espansoMatch = Join-Path $espansoDir "match"

# --------------------------------------------------
# PowerShell
# --------------------------------------------------

Write-Host "Environment"

if ($PSVersionTable.PSVersion.Major -ge 7) {

    Write-Host "✔ PowerShell 7+ detected"

}
else {

    Write-Host "✖ PowerShell 7 required"

}

# --------------------------------------------------
# Chocolatey
# --------------------------------------------------

$choco = Get-Command choco -ErrorAction SilentlyContinue

if ($choco) {

    Write-Host "✔ Chocolatey installed"

}
else {

    Write-Host "✖ Chocolatey not installed"

}

# --------------------------------------------------
# Espanso
# --------------------------------------------------

$espanso = Get-Command espanso -ErrorAction SilentlyContinue

if ($espanso) {

    Write-Host "✔ Espanso installed"

}
else {

    Write-Host "✖ Espanso not found"

}

# --------------------------------------------------
# CopyQ
# --------------------------------------------------

$copyq = Get-Command copyq -ErrorAction SilentlyContinue

if ($copyq) {

    Write-Host "✔ CopyQ installed"

}
else {

    Write-Host "✖ CopyQ not found in PATH"

}

Write-Host ""

# --------------------------------------------------
# Espanso Config
# --------------------------------------------------

Write-Host "Espanso Setup"

if (Test-Path $espansoDir) {

    Write-Host "✔ Espanso config directory found"

}
else {

    Write-Host "✖ Espanso config directory missing"

}

if (Test-Path $espansoMatch) {

    Write-Host "✔ Espanso match directory found"

}
else {

    Write-Host "✖ Espanso match directory missing"

}

Write-Host ""

# --------------------------------------------------
# Snippet Repo
# --------------------------------------------------

Write-Host "Snippet Repository"

if (Test-Path $snippetDir) {

    Write-Host "✔ snippets directory found"

    $files = Get-ChildItem $snippetDir -Filter *.yml -ErrorAction SilentlyContinue

    if ($files.Count -eq 0) {

        Write-Host "⚠ No snippet files yet"

    }
    else {

        Write-Host "✔ snippet files:" $files.Count

    }

}
else {

    Write-Host "✖ snippets directory missing"

}

Write-Host ""

# --------------------------------------------------
# YAML validation
# --------------------------------------------------

if ($files.Count -gt 0) {

    Write-Host "YAML Validation"

    foreach ($file in $files) {

        try {

            Get-Content $file.FullName | ConvertFrom-Yaml | Out-Null
            Write-Host "✔" $file.Name

        }
        catch {

            Write-Host "✖ YAML error in" $file.Name

        }

    }

}

Write-Host ""
Write-Host "Doctor check completed."