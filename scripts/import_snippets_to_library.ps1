# import_snippets_to_library.ps1

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path "$ScriptRoot/.."
$SnippetDir = Join-Path $RepoRoot "snippets"
$LibraryDir = Join-Path $RepoRoot "library"
$LibraryFile = Join-Path $LibraryDir "prompt_library.yml"

$moduleName = "powershell-yaml"

if (-not (Get-Module -ListAvailable -Name $moduleName)) {
    Install-Module $moduleName -Force -Scope CurrentUser -AllowClobber -ErrorAction Stop
}

Import-Module $moduleName -ErrorAction Stop

function Get-CategoryMeta {
    param([string]$Id)

    $known = @{
        model      = @{ label = "Model"; prefix = "model"; order = 10 }
        context    = @{ label = "Context"; prefix = "ctx"; order = 20 }
        characters = @{ label = "Characters"; prefix = "char"; order = 30 }
        scene      = @{ label = "Scene"; prefix = "scene"; order = 40 }
        camera     = @{ label = "Camera"; prefix = "cam"; order = 50 }
        lighting   = @{ label = "Lighting"; prefix = "light"; order = 60 }
        style      = @{ label = "Style"; prefix = "style"; order = 70 }
        quality    = @{ label = "Quality"; prefix = "qual"; order = 80 }
        negative   = @{ label = "Negative"; prefix = "neg"; order = 90 }
        nsfw       = @{ label = "NSFW"; prefix = "nsfw"; order = 100 }
    }

    if ($known.ContainsKey($Id)) {
        return $known[$Id]
    }

    return @{
        label = ($Id.Substring(0, 1).ToUpper() + $Id.Substring(1))
        prefix = $Id
        order = 500
    }
}

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

if (-not (Test-Path $SnippetDir)) {
    throw "Snippet directory not found: $SnippetDir"
}

if (-not (Test-Path $LibraryDir)) {
    New-Item -ItemType Directory -Path $LibraryDir | Out-Null
}

$files = Get-ChildItem $SnippetDir -Filter "comfy_*.yml" | Sort-Object Name

if (-not $files) {
    throw "No generated snippet files found in $SnippetDir"
}

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add("version: 1")
$lines.Add("categories:")

foreach ($file in $files) {
    $id = $file.BaseName -replace "^comfy_", ""
    $meta = Get-CategoryMeta -Id $id
    $yaml = Get-Content $file.FullName -Raw | ConvertFrom-Yaml -ErrorAction Stop
    $matches = @($yaml["matches"])

    $lines.Add("  - id: $(Escape-YamlScalar $id)")
    $lines.Add("    label: $(Escape-YamlScalar $meta.label)")
    $lines.Add("    prefix: $(Escape-YamlScalar $meta.prefix)")
    $lines.Add("    order: $($meta.order)")
    $lines.Add("    snippets:")

    foreach ($match in $matches) {
        $triggerProp = $match["trigger"]
        $replaceProp = $match["replace"]

        if ($null -eq $triggerProp -or $null -eq $replaceProp) {
            continue
        }

        $trigger = [string]$triggerProp
        $replace = [string]$replaceProp
        $snippetId = $trigger.TrimStart(":")
        $prefix = "$($meta.prefix)_"

        if ($snippetId.StartsWith($prefix)) {
            $snippetId = $snippetId.Substring($prefix.Length)
        }

        $lines.Add("      - id: $(Escape-YamlScalar $snippetId)")
        $lines.Add("        trigger: $(Escape-YamlScalar $trigger)")

        $wordProp = $match["word"]

        if ($null -ne $wordProp) {
            $wordValue = [string]$wordProp
            $wordValue = $wordValue.ToLowerInvariant()
            $lines.Add("        word: $wordValue")
        }
        else {
            $lines.Add("        word: true")
        }

        Write-Multiline -Lines $lines -Indent "        " -Key "text" -Value $replace.Trim()
    }
}

[System.IO.File]::WriteAllLines($LibraryFile, $lines, (New-Object System.Text.UTF8Encoding($false)))

try {
    Get-Content $LibraryFile -Raw | ConvertFrom-Yaml -ErrorAction Stop | Out-Null
}
catch {
    throw "Generated library YAML is invalid: $($_.Exception.Message)"
}

Write-Host "Library written: $LibraryFile"
