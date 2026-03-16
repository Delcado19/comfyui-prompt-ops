# Developer Workflow

This document describes the workflow for developing and maintaining snippets.

---

# 1 Edit Snippets

All prompt components are stored in:

```
snippets/
```

Example snippet file:

```
snippets/comfy_context.yml
```

Example snippet:

```yaml
matches:
  - trigger: ":ctx_portrait"
    word: true
    replace: "portrait, centered composition, subject facing camera"
```

---

# 2 Run Development Pipeline

After modifying snippets run the development pipeline:

```powershell
.\scripts\dev.ps1
```

This pipeline performs several validation and generation steps.

---

# Pipeline Tasks

The development pipeline runs the following scripts:

| Script                       | Purpose                        |
| ---------------------------- | ------------------------------ |
| validate_yaml.ps1            | validate YAML syntax           |
| validate_snippets.ps1        | validate snippet structure     |
| check_duplicate_triggers.ps1 | detect duplicate triggers      |
| generate_snippet_docs.ps1    | generate snippet documentation |
| generate_prompt_builder.ps1  | generate prompt builder        |

---

# 3 Install Snippets

Snippets inside the repository are not automatically active.

Install them using:

```powershell
.\scripts\install_snippets.ps1
```

This copies snippets to the Espanso directory.

Source:

```
snippets/
```

Destination:

```
%APPDATA%\espanso\match
```

---

# 4 Restart Services

If Espanso does not reload automatically, restart the services:

```powershell
.\scripts\restart_services.ps1
```

---

## YAML Support

Several development scripts require YAML parsing.

This functionality is provided by the PowerShell command:

ConvertFrom-Yaml

The installer checks whether YAML support is available.

If the command is missing, the installer automatically installs the module:

powershell-yaml

Manual installation (if needed):

Install-Module powershell-yaml -Scope CurrentUser

Verify installation:

Get-Command ConvertFrom-Yaml
