# Snippet System

The snippet system is the core of the ComfyUI Prompt Ops architecture.

Snippets represent reusable prompt components.

---

# Source Of Truth

The central prompt library is:

```text
library/prompt_library.yml
```

Generated Espanso snippet files are written to:

```text
snippets/comfy_*.yml
```

When using the admin workflow, edit the central library and regenerate snippets instead of editing generated `comfy_*.yml` files directly.

Generator:

```powershell
.\scripts\generate_snippets_from_library.ps1
```

Legacy migration from existing generated snippets:

```powershell
.\scripts\import_snippets_to_library.ps1
```

---

# Snippet Format

Each source snippet is defined in the central library. The generator writes Espanso match YAML.

Generated Espanso example:

```yaml
matches:
  - trigger: ":ctx_portrait"
    word: true
    replace: "portrait, centered composition, subject facing camera"
```

---

# Snippet Categories

Prompt components are organized by category.

| Category | Prefix   |
| -------- | -------- |
| Model    | :model\_ |
| Context  | :ctx\_   |
| Scene    | :scene\_ |
| Camera   | :cam\_   |
| Lighting | :light\_ |
| Style    | :style\_ |
| Quality  | :qual\_  |
| Negative | :neg\_   |
| NSFW     | :nsfw\_  |

Each category is stored in a separate YAML file.

Model snippets are prompt-style anchors for local model families. They do not load a checkpoint, UNet, LoRA, VAE, or text encoder. They only add wording that fits the visual behavior observed from local ComfyUI outputs.

Use this naming pattern for new triggers:

```
:<category>_<model-or-look>_<descriptor>
```

Examples:

```
:model_zit
:style_sdxl_inkwash_xianxia
:scene_gothic_throne_room
:light_lowkey_latex
:neg_zit_photo
```

---

# Snippet Files

Snippet files are stored in:

```
snippets/
```

Example:

```
snippets/comfy_context.yml
snippets/comfy_model.yml
snippets/comfy_scene.yml
snippets/comfy_camera.yml
snippets/comfy_lighting.yml
snippets/comfy_style.yml
snippets/comfy_quality.yml
snippets/comfy_negative.yml
snippets/comfy_nsfw.yml
```

---

# Snippet Documentation

Snippet documentation is generated automatically.

Run:

```powershell
.\scripts\generate_snippet_docs.ps1
```

Output file:

```
docs/snippets.md
```

This file contains a table of all triggers and their expansions.

---

# Snippet Deployment

Snippets must be installed into Espanso before they become active.

Run:

```powershell
.\scripts\install_snippets.ps1
```

This copies snippet files to the Espanso match directory.

Default location:

```
%APPDATA%\espanso\match
```
