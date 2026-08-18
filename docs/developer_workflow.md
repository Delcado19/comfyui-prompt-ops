# Developer Workflow

This document describes the workflow for developing and maintaining snippets.

---

# 1 Edit Snippets

All prompt components are maintained in the central library:

```
library/prompt_library.yml
```

The Espanso files under `snippets/` are generated output.

Start the local admin UI:

```powershell
npm run admin
```

Generated snippets are written to:

```
snippets/
```

Example generated snippet file:

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
| generate_snippets_from_library.ps1 | generate Espanso snippet files |
| validate_yaml.ps1            | validate YAML syntax           |
| test_powershell_parse.ps1    | validate PowerShell syntax     |
| validate_snippets.ps1        | validate snippet structure     |
| check_duplicate_triggers.ps1 | detect duplicate triggers      |
| generate_prompt_builder.ps1  | generate prompt builder        |
| generate_snippet_docs.ps1    | generate snippet documentation |

`import_snippets_to_library.ps1` and `export_existing_snippets.ps1` are one-off migration tools, not part of this pipeline — see the comment at the top of each script.

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

To switch Espanso + CopyQ on or off on demand (neither is registered to
autostart with the OS by this repo's scripts), use the toggle instead — it
starts both if neither is running, or stops both if either is running:

```powershell
.\scripts\toggle_services.ps1
```

Both scripts are plain PowerShell and run the same way under `pwsh` on
Linux/macOS as on Windows.

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
