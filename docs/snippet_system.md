# Snippet System

The snippet system is the core of the ComfyUI Prompt Ops architecture.

Snippets represent reusable prompt components.

---

# Snippet Format

Each snippet is defined in YAML using Espanso's match format.

Example:

```yaml
matches:
  - trigger: ":ctx_portrait"
    word: true
    replace: "portrait, centered composition, subject facing camera"
```

---

# Snippet Categories

Prompt components are organized by category.

| Category   | Prefix     |
| ---------- | ---------- |
| Context    | :ctx\_     |
| Characters | :char\_    |
| Scene      | :scene\_   |
| Camera     | :cam\_     |
| Lighting   | :light\_   |
| Style      | :style\_   |
| Quality    | :quality\_ |
| Negative   | :neg\_     |
| NSFW       | :nsfw\_    |

Each category is stored in a separate YAML file.

---

# Snippet Files

Snippet files are stored in:

```
snippets/
```

Example:

```
snippets/comfy_context.yml
snippets/comfy_characters.yml
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
