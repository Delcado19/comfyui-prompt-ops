Write-Host ""
Write-Host "================================="
Write-Host " ComfyUI Prompt Ops Dev Pipeline"
Write-Host "================================="

# --------------------------------
# Step 1: YAML validation
# --------------------------------

Write-Host ""
Write-Host "Step 1: YAML validation"

.\scripts\validate_yaml.ps1

if ($LASTEXITCODE -ne 0) {
    Write-Host "Pipeline aborted."
    exit 1
}

# --------------------------------
# Step 2: Snippet validation
# --------------------------------

Write-Host ""
Write-Host "Step 2: Snippet validation"

.\scripts\validate_snippets.ps1

if ($LASTEXITCODE -ne 0) {
    Write-Host "Pipeline aborted."
    exit 1
}

# --------------------------------
# Step 3: Duplicate triggers
# --------------------------------

Write-Host ""
Write-Host "Step 3: Checking duplicate triggers"

.\scripts\check_duplicate_triggers.ps1

if ($LASTEXITCODE -ne 0) {
    Write-Host "Pipeline aborted."
    exit 1
}

# --------------------------------
# Step 4: Generate docs
# --------------------------------

Write-Host ""
Write-Host "Step 4: Generate documentation"

.\scripts\generate_snippet_docs.ps1

# --------------------------------
# Step 5: Generate prompt builder
# --------------------------------

Write-Host ""
Write-Host "Step 5: Generate prompt builder"

.\scripts\generate_prompt_builder.ps1

Write-Host ""
Write-Host "Dev pipeline completed."