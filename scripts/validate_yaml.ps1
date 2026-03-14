Write-Host ""
Write-Host "Checking YAML syntax..."

$root = Resolve-Path "$PSScriptRoot\.."
$snippetDir = Join-Path $root "snippets"

$files = Get-ChildItem $snippetDir -Filter *.yml

$errors = $false

foreach ($file in $files) {

    try {

        $content = Get-Content $file.FullName -Raw

        $content | ConvertFrom-Yaml | Out-Null

        Write-Host "OK:" $file.Name

    }
    catch {

        Write-Host "ERROR:" $file.Name
        $errors++

    }

}

if ($errors) {

    Write-Host ""
    Write-Host "YAML validation failed."
    exit 1

}

Write-Host ""
Write-Host "All YAML files valid."