# generate_prompt_builder.ps1
# Builds snippets/zz_prompt_builder.yml from comfy_*.yml files

$repoRoot   = Resolve-Path "$PSScriptRoot\.."
$snippetDir = Join-Path $repoRoot "snippets"
$outputFile = Join-Path $snippetDir "zz_prompt_builder.yml"

$categoryOrder = @(
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

$categories = @{}

# --------------------------------------------------
# Read snippet files
# --------------------------------------------------

Get-ChildItem $snippetDir -Filter "comfy_*.yml" | ForEach-Object {

    $file = $_
    $name = $file.BaseName -replace "^comfy_", ""

    $content = Get-Content $file.FullName -Raw
    $yaml    = $content | ConvertFrom-Yaml

    if (-not $yaml.matches) { return }

    $values = @()

    foreach ($m in $yaml.matches) {

        if (-not $m.replace) { continue }

        $value = $m.replace.Trim()
        $value = $value -replace "\r?\n"," "

        # skip templates
        if ($value -match "{{") { continue }

        $values += $value
    }

    if ($values.Count -gt 0) {
        $categories[$name] = $values | Sort-Object -Unique
    }
}

Write-Host ""
Write-Host "Detected categories:"

foreach ($c in $categories.Keys) {
    $label = $c.Substring(0,1).ToUpper() + $c.Substring(1)
    Write-Host " - $label ($($categories[$c].Count) entries)"
}

# --------------------------------------------------
# Build form parameters
# --------------------------------------------------

$formParams = @{}

foreach ($cat in $categoryOrder) {

    if ($categories.ContainsKey($cat)) {

        $values = @("none") + $categories[$cat]

        $formParams[$cat] = @{
            type   = "choice"
            values = $values
        }
    }
}

# --------------------------------------------------
# Build replace string
# --------------------------------------------------

$replaceParts = @()

foreach ($cat in $categoryOrder) {

    if ($formParams.ContainsKey($cat)) {

        $replaceParts += "{{prompt.${cat}}}"
    }
}

$replaceString = $replaceParts -join " "

# --------------------------------------------------
# Generate YAML
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

foreach ($cat in $categoryOrder) {

    if ($formParams.ContainsKey($cat)) {

        $label = $cat.Substring(0,1).ToUpper() + $cat.Substring(1)
        $lines += "            ${label}: [[${cat}]]"
    }
}

$lines += ""
$lines += "          fields:"

foreach ($cat in $categoryOrder) {

    if ($formParams.ContainsKey($cat)) {

        $lines += "            ${cat}:"
        $lines += "              type: choice"
        $lines += "              values:"

        foreach ($v in $formParams[$cat].values) {

            $escaped = $v.Replace('"','\"')
            $lines += "                - `"$escaped`""
        }
    }
}

$lines | Set-Content $outputFile -Encoding UTF8

# --------------------------------------------------
# Validate generated YAML
# --------------------------------------------------

try {
    Get-Content $outputFile -Raw | ConvertFrom-Yaml -ErrorAction Stop | Out-Null
    Write-Host "YAML validation successful."
}
catch {
    Write-Host ""
    Write-Host "ERROR: Generated YAML is invalid!" -ForegroundColor Red
    Write-Host $_.Exception.Message
    Write-Host ""

    if ($_.InvocationInfo) {
        Write-Host "Location:" -ForegroundColor Yellow
        Write-Host "Line: $($_.InvocationInfo.ScriptLineNumber)"
        Write-Host "Code: $($_.InvocationInfo.Line)"
    }

    exit 1
}

Write-Host ""
Write-Host "Prompt Builder generated:"
Write-Host $outputFile