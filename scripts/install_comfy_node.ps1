# install_comfy_node.ps1
#
# Deploys comfyui_node/prompt_ops (the Prompt Ops Browser node) into a
# ComfyUI install's custom_nodes/. Not part of scripts/dev.ps1 -- this
# targets ComfyUI, not Espanso, and only needs to run once per ComfyUI
# install or after the node's Python/JS code changes (library edits apply
# on their own, no re-install needed, though new/renamed triggers need a
# ComfyUI restart/reload to show up in the node's filters).

param(
    [string]$ComfyUIPath = $env:COMFYUI_PATH,
    [switch]$dryrun
)

$ErrorActionPreference = "Stop"

$root = Resolve-Path "$PSScriptRoot\.."
$sourceDir = Join-Path $root "comfyui_node\prompt_ops"
$libraryFile = (Resolve-Path (Join-Path $root "library\prompt_library.yml")).Path

if (-not $ComfyUIPath) {
    throw "ComfyUI path not set. Pass -ComfyUIPath <path to ComfyUI> or set `$env:COMFYUI_PATH."
}

if (-not (Test-Path $ComfyUIPath)) {
    throw "ComfyUI path not found: $ComfyUIPath"
}

$customNodesDir = Join-Path $ComfyUIPath "custom_nodes"

if (-not (Test-Path $customNodesDir)) {
    throw "custom_nodes directory not found under $ComfyUIPath. Is this really a ComfyUI install?"
}

$targetDir = Join-Path $customNodesDir "comfyui_prompt_ops"

if ($dryrun) {
    Write-Host "[DRYRUN] Would copy $sourceDir -> $targetDir"
    Write-Host "[DRYRUN] Would point library_path.txt at $libraryFile"
    exit 0
}

if (Test-Path $targetDir) {
    Remove-Item $targetDir -Recurse -Force
}

Copy-Item $sourceDir $targetDir -Recurse -Force

Set-Content -Path (Join-Path $targetDir "library_path.txt") -Value $libraryFile -NoNewline -Encoding UTF8

Write-Host "Installed Prompt Ops Browser node to $targetDir"
Write-Host "Restart ComfyUI (or use its 'reload custom nodes' feature) to pick it up."
