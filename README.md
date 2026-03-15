# 🚀 ComfyUI Prompt Ops

![ComfyUI](https://img.shields.io/badge/ComfyUI-compatible-purple)
![License](https://img.shields.io/github/license/delcado19/comfyui-prompt-ops)
![PowerShell](https://img.shields.io/badge/PowerShell-7+-5391FE?logo=powershell&logoColor=white)
![Platform](https://img.shields.io/badge/platform-Windows-blue)
![Espanso](https://img.shields.io/badge/espanso-supported-orange)
![ComfyUI](https://img.shields.io/badge/ComfyUI-workflow-purple)
![Stars](https://img.shields.io/github/stars/delcado19/comfyui-prompt-ops?style=social)
![Last Commit](https://img.shields.io/github/last-commit/delcado19/comfyui-prompt-ops)

**Composable prompt engineering for ComfyUI using Espanso.**

## 📑 Table of Contents

- [Quick Start](#-quick-start)
- [What This Project Does](#-what-this-project-does)
- [Concept](#-concept)
- [Features](#-features)
- [Tech Stack](#-tech-stack)
- [Installation](#-installation)
- [Dry Run](#-dry-run)
- [Project Structure](#-project-structure)
- [Snippet Architecture](#-snippet-architecture)
- [Example Workflow](#-example-workflow)
- [Development](#-development)
- [Generated Documentation](#-generated-documentation)
- [Adding New Snippets](#-adding-new-snippets)
- [Dev Utilities](#-dev-utilities)
- [Roadmap](#-roadmap)
- [Use Cases](#-use-cases)
- [Contributing](#-contributing)
- [License](#-license)

## ⚡ Quick Start

```bash
git clone https://github.com/Delcado19/comfyui-prompt-ops.git
cd comfyui-prompt-ops
pwsh .\installer\install.ps1
```

ComfyUI Prompt Ops transforms **Espanso snippets** into a **modular prompt-building system**.
Instead of manually typing long prompts, you compose them using small reusable building blocks.

This makes prompts:

- faster to write
- easier to maintain
- consistent across projects
- modular and scalable

---

## ✨ What This Project Does

ComfyUI Prompt Ops turns Espanso into a **prompt composition engine**.

Instead of writing something like:

```text
portrait photo of a woman, cinematic lighting, soft shadows, close-up camera shot, shallow depth of field, highly detailed skin, studio lighting
```

You can simply type:

```text
:char_woman :ctx_portrait :cam_closeup :light_soft :style_cinematic
```

Espanso automatically expands the snippets into the full prompt.

---

## 🧠 Concept

Prompt Ops follows a **modular architecture**:

```
character + context + camera + lighting + style
```

Example composition:

```
:char_woman :ctx_portrait :cam_closeup :light_soft :style_cinematic
```

Which becomes a complete prompt.

---

## ⚙️ Features

✔ Modular prompt snippets
✔ Espanso-powered text expansion
✔ Automated Windows installer
✔ Dependency management via Chocolatey
✔ Clipboard workflow via CopyQ
✔ Developer validation tools
✔ Auto-generated snippet documentation
✔ Scalable prompt architecture

---

## 🧰 Tech Stack

| Tool             | Purpose               |
| ---------------- | --------------------- |
| **Espanso**      | Text expansion engine |
| **CopyQ**        | Clipboard manager     |
| **PowerShell 7** | Automation            |
| **Chocolatey**   | Package management    |
| **Git**          | Version control       |

---

## 📦 Installation

### 1️⃣ Clone the repository

```bash
git clone https://github.com/Delcado19/comfyui-prompt-ops.git
cd comfyui-prompt-ops
```

### 2️⃣ Run the installer

```powershell
.\installer\install.ps1
```

The installer automatically:

- elevates to **Administrator**
- checks **PowerShell version**
- verifies **Chocolatey**
- installs dependencies
- installs snippets
- restarts services
- reloads Espanso

---

## 🧪 Dry Run

Simulate the install process without making changes:

```powershell
.\installer\install.ps1 -dryrun
```

---

## 📂 Project Structure

```
comfyui-prompt-ops
│
├─ installer
│  └─ install.ps1
│
├─ scripts
│  ├─ doctor.ps1
│  ├─ install_snippets.ps1
│  ├─ restart_services.ps1
│  ├─ validate_snippets.ps1
│  ├─ validate_yaml.ps1
│  ├─ check_duplicate_triggers.ps1
│  ├─ generate_snippet_docs.ps1
│  ├─ dev_generate_docs.ps1
│  ├─ dev.ps1
│  └─ export_existing_snippets.ps1
│
├─ snippets
│  ├─ base.yml
│  ├─ comfy_camera.yml
│  ├─ comfy_characters.yml
│  ├─ comfy_context.yml
│  ├─ comfy_lighting.yml
│  ├─ comfy_master.yml
│  ├─ comfy_negative.yml
│  ├─ comfy_nsfw.yml
│  ├─ comfy_scene.yml
│  ├─ comfy_style.yml
│  └─ default.yml
│
└─ docs
   └─ snippets.md
```

---

## 🧩 Snippet Architecture

Prompt elements are grouped by **prefix category**.

| Prefix     | Category         | Example            |
| ---------- | ---------------- | ------------------ |
| `:char_`   | Character        | `:char_woman`      |
| `:ctx_`    | Context          | `:ctx_portrait`    |
| `:cam_`    | Camera           | `:cam_closeup`     |
| `:light_`  | Lighting         | `:light_soft`      |
| `:style_`  | Style            | `:style_cinematic` |
| `:scene_`  | Scene            | `:scene_city`      |
| `:neg_`    | Negative prompts | `:neg_blurry`      |
| `:master_` | Prompt presets   | `:master_portrait` |

---

## 🧪 Example Workflow

Typing:

```
:ctx_portrait
```

Expands to:

```
portrait composition, centered framing, subject facing camera
```

A full prompt build might look like:

```
:char_woman :ctx_portrait :cam_closeup :light_soft :style_cinematic
```

---

## 🧑‍💻 Development

Run the development pipeline:

```powershell
.\scripts\dev.ps1
```

This runs:

1️⃣ snippet validation
2️⃣ YAML validation
3️⃣ duplicate trigger detection
4️⃣ snippet documentation generation

---

## 📄 Generated Documentation

Snippet docs are generated automatically:

```
docs/snippets.md
```

Run:

```powershell
.\scripts\generate_snippet_docs.ps1
```

---

## ➕ Adding New Snippets

Create a new file in:

```
snippets/
```

Example snippet:

```yaml
matches:
  - trigger: ":ctx_portrait"
    word: true
    replace: "portrait composition, centered framing, subject facing camera"
```

Then run:

```powershell
.\scripts\dev.ps1
```

---

## 🛠 Dev Utilities

| Script                         | Function                   |
| ------------------------------ | -------------------------- |
| `doctor.ps1`                   | environment diagnostics    |
| `validate_snippets.ps1`        | snippet validation         |
| `validate_yaml.ps1`            | YAML syntax check          |
| `check_duplicate_triggers.ps1` | trigger conflict detection |
| `generate_snippet_docs.ps1`    | auto documentation         |
| `export_existing_snippets.ps1` | migrate snippets           |

---

## 🧭 Roadmap

Planned improvements:

- prompt builder snippets
- advanced prompt templates
- trigger collision prevention
- snippet autocomplete docs
- snippet categories
- ComfyUI workflow presets
- advanced prompt macros

---

## 🧑‍🎨 Use Cases

Perfect for:

- Stable Diffusion prompt engineering
- ComfyUI workflows
- fast prompt iteration
- reusable prompt libraries
- AI art pipelines

---

## 🤝 Contributing

Contributions are welcome.

Ideas:

- new prompt snippet packs
- better documentation
- installer improvements
- cross-platform support

---

## 📜 License

MIT License

---

## ⭐ If You Like This Project

Consider giving it a star on GitHub.
It helps others discover the project.
