# Contributing to ComfyUI Prompt Ops

Thank you for your interest in contributing.

This project aims to build a **modular prompt engineering system for ComfyUI** using Espanso snippets.

---

# Ways to Contribute

You can help by:

- adding new prompt snippets
- improving documentation
- fixing installer issues
- improving validation scripts
- expanding snippet libraries

---

# Development Setup

Clone the repository:

```
git clone https://github.com/yourname/comfyui-prompt-ops.git
cd comfyui-prompt-ops
```

Run the development pipeline:

```
.\scripts\dev.ps1
```

This will validate snippets and generate documentation.

---

# Adding Snippets

Snippets live inside the `snippets` directory.

Example:

```
matches:

  - trigger: ":ctx_portrait"
    word: true
    replace: "portrait composition, centered framing, subject facing camera"
```

Guidelines:

- always use the correct prefix
- avoid duplicate triggers
- keep prompts clean and composable

---

# Prefix System

| Prefix    | Purpose          |
| --------- | ---------------- |
| :char\_   | characters       |
| :ctx\_    | context          |
| :cam\_    | camera           |
| :light\_  | lighting         |
| :style\_  | visual style     |
| :scene\_  | environment      |
| :neg\_    | negative prompts |
| :master\_ | prompt presets   |

---

# Commit Style

We use **conventional commits**.

Examples:

```
feat: add cyberpunk style snippets
fix: installer admin elevation
docs: improve README
refactor: simplify snippet validation
```

---

# Pull Requests

Before submitting a PR:

1. run validation scripts
2. ensure no duplicate triggers
3. ensure YAML syntax is valid

Then open a pull request with a clear description.
