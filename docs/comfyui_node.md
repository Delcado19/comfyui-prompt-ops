# ComfyUI Node

A minimal, read-only adapter node: a dropdown over every snippet trigger in
`library/prompt_library.yml`, output as a `STRING`. Wire it into any node
that accepts text (a CLIP Text Encode, a string concat node, etc.).

This is a second way to consume the same library, not a replacement for
Espanso. Espanso expands triggers system-wide, in any application; this node
only exists inside a ComfyUI graph, but the selection then lives in the
workflow JSON — reproducible and shareable without needing Espanso installed
on the machine that opens the workflow.

The node never writes to the library. Edit snippets via the admin UI or by
hand as usual, then re-run `scripts/dev.ps1`.

---

## Install

```powershell
.\scripts\install_comfy_node.ps1 -ComfyUIPath "G:\ComfyUI-Easy-Install\ComfyUI"
```

Or set `$env:COMFYUI_PATH` once and omit `-ComfyUIPath` on future runs.

This copies `comfyui_node/prompt_ops/` into `<ComfyUIPath>\custom_nodes\comfyui_prompt_ops`
and writes a `library_path.txt` inside it pointing at this repo's
`library/prompt_library.yml`. Restart ComfyUI (or use its "reload custom
nodes" feature) to pick it up.

Re-run the install script only when the node's Python code changes, or when
you move/rename the repo (so `library_path.txt` points at the right file).
Library edits (new/changed snippet text) apply automatically — no
re-install needed.

---

## Behavior

- **Snippet text edits** apply immediately: the node re-reads the library
  file on every execution, and `IS_CHANGED` returns the file's mtime so
  ComfyUI won't serve a stale cached value.
- **Added, removed, or renamed triggers** only show up in the dropdown after
  a ComfyUI restart/reload — the list of options is built once when ComfyUI
  asks for the node's `INPUT_TYPES`, which the frontend caches for the
  session.
- Selecting a trigger that has since been deleted from the library raises a
  clear error at run time instead of failing silently.

---

## Requirements

`PyYAML` in ComfyUI's Python environment. ComfyUI-Easy-Install's embedded
Python already ships it; if you're on a different ComfyUI setup and the node
fails to load, install it into that environment:

```
pip install pyyaml
```
