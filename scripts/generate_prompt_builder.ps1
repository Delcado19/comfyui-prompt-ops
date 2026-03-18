# generate_prompt_builder.ps1

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
$OutputFile = Join-Path $SnippetDir "zz_prompt_builder.yml"

if (-not (Test-Path $SnippetDir)) {
    throw "Snippet directory not found: $SnippetDir"
}

# --------------------------------------------------
# YAML MODULE CHECK
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

Import-Module powershell-yaml -ErrorAction Stop

# --------------------------------------------------
# CONFIG
# --------------------------------------------------

$CategoryOrder = @(
    "context",
    "characters",
    "scene",
    "camera",
    "lighting",
    "style",
    "quality",
    "negative",
    "nsfw"
)

$Categories = @{}

# --------------------------------------------------
# READ SNIPPETS
# --------------------------------------------------

$files = Get-ChildItem $SnippetDir -Filter "comfy_*.yml"

if (-not $files) {
    throw "No snippet files found in $SnippetDir"
}

foreach ($file in $files) {

    Write-Host "Processing: $($file.Name)"

    $name = $file.BaseName -replace "^comfy_", ""

    $content = Get-Content $file.FullName -Raw

    if (-not $content.Trim()) {
        throw "File is empty: $($file.Name)"
    }

    try {
        $yaml = $content | ConvertFrom-Yaml -ErrorAction Stop
    }
    catch {
        throw "YAML parsing failed in $($file.Name): $($_.Exception.Message)"
    }

    if (-not $yaml.matches) {
        Write-Warning "No matches found in $($file.Name)"
        continue
    }

    $values = @()

    foreach ($m in $yaml.matches) {

        if (-not $m.replace) { continue }

        $value = $m.replace.Trim()
        $value = $value -replace "\r?\n"," "

        # skip templates
        if ($value -match "{{") { continue }

        if (-not [string]::IsNullOrWhiteSpace($value)) {
            $values += $value
        }
    }

    if ($values.Count -gt 0) {
        $Categories[$name] = $values | Sort-Object -Unique
    }
    else {
        Write-Warning "No usable values in $($file.Name)"
    }
}

if ($Categories.Count -eq 0) {
    throw "No categories generated. All inputs empty or invalid."
}

# --------------------------------------------------
# DEBUG OUTPUT
# --------------------------------------------------

Write-Host ""
Write-Host "Detected categories:"

foreach ($c in $Categories.Keys | Sort-Object) {
    $label = $c.Substring(0,1).ToUpper() + $c.Substring(1)
    Write-Host " - $label ($($Categories[$c].Count) entries)"
}

# --------------------------------------------------
# BUILD FORM PARAMS
# --------------------------------------------------

$FormParams = @{}

foreach ($cat in $CategoryOrder) {

    if ($Categories.ContainsKey($cat)) {

        $values = @("none") + $Categories[$cat]

        $FormParams[$cat] = @{
            type   = "choice"
            values = $values
        }
    }
}

if ($FormParams.Count -eq 0) {
    throw "No form parameters generated"
}

# --------------------------------------------------
# BUILD REPLACE STRING
# --------------------------------------------------

$replaceParts = @()

foreach ($cat in $CategoryOrder) {

    if ($FormParams.ContainsKey($cat)) {
        $replaceParts += "{{prompt.${cat}}}"
    }
}

$replaceString = $replaceParts -join " "

if (-not $replaceString) {
    throw "Replace string is empty"
}

# --------------------------------------------------
# GENERATE YAML
# --------------------------------------------------

$lines = @()

$lines += "matches:"
$lines += "  - trigger: `":prompt`""
$lines += "    replace: `"$replaceString`""
$lines += "    vars:"
$lines += "      - name: prompt"
$lines += "        type: form"
$lines += "        params:"
$lines += "          layout: |"

foreach ($cat in $CategoryOrder) {

    if ($FormParams.ContainsKey($cat)) {

        $label = $cat.Substring(0,1).ToUpper() + $cat.Substring(1)
        $lines += "            ${label}: [[${cat}]]"
    }
}

$lines += ""
$lines += "          fields:"

foreach ($cat in $CategoryOrder) {

    if ($FormParams.ContainsKey($cat)) {

        $lines += "            ${cat}:"
        $lines += "              type: choice"
        $lines += "              values:"

        foreach ($v in $FormParams[$cat].values) {

            $escaped = $v.Replace('"','\"')
            $lines += "                - `"$escaped`""
        }
    }
}

# --------------------------------------------------
# WRITE FILE (NO BOM!)
# --------------------------------------------------

[System.IO.File]::WriteAllLines($OutputFile, $lines, (New-Object System.Text.UTF8Encoding($false)))

# --------------------------------------------------
# VALIDATE OUTPUT YAML
# --------------------------------------------------

try {
    Get-Content $OutputFile -Raw | ConvertFrom-Yaml -ErrorAction Stop | Out-Null
}
catch {
    throw "Generated YAML is invalid: $($_.Exception.Message)"
}

# --------------------------------------------------
# DONE
# --------------------------------------------------

Write-Host ""
Write-Host "SUCCESS: Prompt Builder generated"
Write-Host $OutputFile