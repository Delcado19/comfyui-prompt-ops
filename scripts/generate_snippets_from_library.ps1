# generate_snippets_from_library.ps1

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path "$ScriptRoot/.."
$SnippetDir = Join-Path $RepoRoot "snippets"
$LibraryFile = Join-Path $RepoRoot "library\prompt_library.yml"

$moduleName = "powershell-yaml"

if (-not (Get-Module -ListAvailable -Name $moduleName)) {
    Install-Module $moduleName -Force -Scope CurrentUser -AllowClobber -ErrorAction Stop
}

Import-Module $moduleName -ErrorAction Stop

function Escape-YamlScalar {
    param([string]$Value)
    return '"' + $Value.Replace('\', '\\').Replace('"', '\"') + '"'
}

function Write-Multiline {
    param(
        [System.Collections.Generic.List[string]]$Lines,
        [string]$Indent,
        [string]$Key,
        [string]$Value
    )

    $Lines.Add("${Indent}${Key}: |")
    foreach ($line in ($Value -split "`r?`n")) {
        $Lines.Add("${Indent}  $line")
    }
}

function Assert-Id {
    param(
        [string]$Name,
        [string]$Value
    )

    if ($Value -notmatch "^[a-z0-9][a-z0-9_]*$") {
        throw "${Name} must use lowercase letters, numbers, and underscores only: $Value"
    }
}

if (-not (Test-Path $LibraryFile)) {
    throw "Prompt library not found: $LibraryFile"
}

if (-not (Test-Path $SnippetDir)) {
    New-Item -ItemType Directory -Path $SnippetDir | Out-Null
}

$library = Get-Content $LibraryFile -Raw | ConvertFrom-Yaml -ErrorAction Stop

if (-not $library["categories"]) {
    throw "Prompt library has no categories."
}

$seenTriggers = @{}
$generatedFiles = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$categories = @($library["categories"]) | Sort-Object { $_["order"] }, { $_["id"] }

foreach ($category in $categories) {
    $categoryIdProp = $category["id"]
    $categoryPrefixProp = $category["prefix"]
    $categorySnippetsProp = $category["snippets"]

    if ($null -eq $categoryIdProp -or -not $categoryIdProp) {
        throw "Category is missing id."
    }

    $categoryId = [string]$categoryIdProp

    if ($null -eq $categoryPrefixProp -or -not $categoryPrefixProp) {
        throw "Category '$categoryId' is missing prefix."
    }

    $categoryPrefix = [string]$categoryPrefixProp

    Assert-Id -Name "Category id" -Value $categoryId
    Assert-Id -Name "Category prefix" -Value $categoryPrefix

    $outputFile = Join-Path $SnippetDir "comfy_$categoryId.yml"
    [void]$generatedFiles.Add((Resolve-Path -LiteralPath (Split-Path $outputFile -Parent)).Path + "\" + (Split-Path $outputFile -Leaf))

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add("matches:")

    $snippets = @()

    if ($null -ne $categorySnippetsProp) {
        $snippets = @($categorySnippetsProp)
    }

    foreach ($snippet in $snippets) {
        $snippetIdProp = $snippet["id"]
        $snippetTextProp = $snippet["text"]
        $snippetTriggerProp = $snippet["trigger"]
        $snippetWordProp = $snippet["word"]

        if ($null -eq $snippetIdProp -or -not $snippetIdProp) {
            throw "Category '$categoryId' contains a snippet without id."
        }

        $snippetId = [string]$snippetIdProp

        if ($null -eq $snippetTextProp -or -not $snippetTextProp) {
            throw "Snippet '$snippetId' in category '$categoryId' is missing text."
        }

        $snippetText = [string]$snippetTextProp

        Assert-Id -Name "Snippet id" -Value $snippetId

        $trigger = $null

        if ($null -ne $snippetTriggerProp) {
            $trigger = [string]$snippetTriggerProp
        }

        if (-not $trigger) {
            $trigger = ":$($categoryPrefix)_$snippetId"
        }

        if ($trigger -notmatch "^:[a-z0-9_]+$") {
            throw "Invalid trigger '$trigger'. Use lowercase letters, numbers, and underscores after ':'."
        }

        if ($seenTriggers.ContainsKey($trigger)) {
            throw "Duplicate trigger '$trigger' in '$categoryId' and '$($seenTriggers[$trigger])'."
        }

        $seenTriggers[$trigger] = $categoryId

        $word = $true

        if ($null -ne $snippetWordProp) {
            $word = [bool]$snippetWordProp
        }

        $lines.Add("  - trigger: $(Escape-YamlScalar $trigger)")
        $lines.Add("    word: $(([string]$word).ToLowerInvariant())")
        Write-Multiline -Lines $lines -Indent "    " -Key "replace" -Value $snippetText.Trim()
    }

    [System.IO.File]::WriteAllLines($outputFile, $lines, (New-Object System.Text.UTF8Encoding($false)))

    try {
        Get-Content $outputFile -Raw | ConvertFrom-Yaml -ErrorAction Stop | Out-Null
    }
    catch {
        throw "Generated snippet YAML is invalid in ${categoryId}: $($_.Exception.Message)"
    }

    Write-Host "Generated: $outputFile"
}

$existingGenerated = Get-ChildItem $SnippetDir -Filter "comfy_*.yml" -File

foreach ($file in $existingGenerated) {
    if (-not $generatedFiles.Contains($file.FullName)) {
        Remove-Item -LiteralPath $file.FullName -Force
        Write-Host "Removed stale generated file: $($file.FullName)"
    }
}

Write-Host "Generated categories: $($categories.Count)"
Write-Host "Generated triggers: $($seenTriggers.Count)"
