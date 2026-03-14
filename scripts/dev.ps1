Write-Host ""
Write-Host "================================="
Write-Host " ComfyUI Prompt Ops Dev Pipeline"
Write-Host "================================="

# --------------------------------
# Step 1: Linter
# --------------------------------

Write-Host ""
Write-Host "Step 1: Snippet Linter"

.\scripts\validate_snippets.ps1

if ($LASTEXITCODE -ne 0) {

    Write-Host ""
    Write-Host "Dev pipeline aborted due to linter errors."
    exit 1

}

# --------------------------------
# Step 2: Documentation
# --------------------------------

Write-Host ""
Write-Host "Step 2: Generate documentation"

.\scripts\generate_snippet_docs.ps1

Write-Host ""
Write-Host "Dev pipeline completed."