param(
    [switch]$dryrun
)

Write-Host ""
Write-Host "Installing snippets..."

$root = Resolve-Path "$PSScriptRoot\.."
$snippetDir = Join-Path $root "snippets"
$configDir = Join-Path $root "config"

# Espanso's dirs differ per OS: %APPDATA% on Windows, XDG config on Linux/macOS.
if ($IsWindows) {
    $espansoRoot = Join-Path $env:APPDATA "espanso"
}
else {
    $espansoRoot = Join-Path $HOME ".config/espanso"
}
$espansoMatch = Join-Path $espansoRoot "match"
$espansoConfig = Join-Path $espansoRoot "config"

foreach ($dir in @($espansoMatch, $espansoConfig)) {
    if (!(Test-Path $dir)) {
        if ($dryrun) {
            Write-Host "[DRYRUN] Would create $dir"
        }
        else {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }
}

$files = Get-ChildItem $snippetDir -Filter *.yml

$count = 0

foreach ($file in $files) {

    if ($dryrun) {

        Write-Host "[DRYRUN] Would copy $($file.Name)"

    }
    else {

        Copy-Item $file.FullName $espansoMatch -Force
        Write-Host "Copied $($file.Name)"

    }

    $count++

}

# config/*.yml holds Espanso's own settings (backend, shortcuts, ...), not
# match triggers, so it's deployed to Espanso's config dir, not match/.
if (Test-Path $configDir) {

    $configFiles = Get-ChildItem $configDir -Filter *.yml

    foreach ($file in $configFiles) {

        if ($dryrun) {
            Write-Host "[DRYRUN] Would copy config/$($file.Name)"
        }
        else {
            Copy-Item $file.FullName $espansoConfig -Force
            Write-Host "Copied config/$($file.Name)"
        }

        $count++

    }

}

# Remove previously-generated files whose source no longer exists (e.g.
# after a category is deleted from the library, or after default.yml moved
# from snippets/ to config/) so Espanso doesn't keep loading dead triggers,
# or a stray config file, left behind in match/. Only touches filenames this
# script is known to have generated/copied there itself — never base.yml or
# anything else Espanso or the user placed in match/.
$sourceNames = $files | ForEach-Object { $_.Name }
$staleFiles = Get-ChildItem $espansoMatch -Filter "*.yml" -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -eq "default.yml" -or $_.Name -like "comfy_*.yml" -or $_.Name -eq "zz_prompt_builder.yml" } |
    Where-Object { $sourceNames -notcontains $_.Name }

foreach ($stale in $staleFiles) {

    if ($dryrun) {
        Write-Host "[DRYRUN] Would remove stale $($stale.Name)"
    }
    else {
        Remove-Item $stale.FullName -Force
        Write-Host "Removed stale $($stale.Name)"
    }

}

Write-Host ""
Write-Host "Snippets processed:" $count
