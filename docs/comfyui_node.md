# ComfyUI Node: Prompt Ops Browser

A read-only browser over every snippet in `library/prompt_library.yml`,
built as a ComfyUI custom node so the library is usable inside a workflow
graph without Espanso installed on the machine that opens it.

This is a second way to consume the same library, not a replacement for
Espanso. The node never writes to the library. Edit snippets via the admin
UI or by hand as usual, then re-run `scripts/dev.ps1`.

---

## UI

The node has two editable multiline text fields, `positive_text` and
`negative_text`, plus a filter/insert row above them:

- **polarity**: Positive / Negative — everything except the "Negative"
  category counts as positive.
- **category**: Alle, or one category label (Scene, Camera, Lighting, …).
- **entry**: the filtered list of matches, each shown as
  `[Category] :trigger — full snippet text` (no guessing what an
  abbreviation means).
- **mode**: Getrennt / Nur ein Prompt — controls where a *negative*-polarity
  entry gets appended. "Getrennt" sends it to `negative_text`; "Nur ein
  Prompt" sends it to `positive_text` instead, for workflows that only have
  a single prompt input (e.g. zero-out conditioning instead of a separate
  negative encode).
- **Einfügen** button: appends the selected entry's text to the target
  field (comma-separated), keeping whatever you've already typed by hand.

Wire `positive`/`negative` (the node's STRING outputs) into your
`CLIP Text Encode` node(s) same as any other text source.

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

Re-run the install script only when the node's Python/JS code changes, or
when you move/rename the repo (so `library_path.txt` points at the right
file). Snippet text edits apply on the next node reload — no re-install
needed.

---

## Behavior

- The filter/entry lists are fetched once per node instance, from a small
  `/prompt_ops/library` route the node registers, which re-reads
  `library/prompt_library.yml` on every request.
- **Added, removed, or renamed triggers** only show up after a ComfyUI
  restart/reload (or adding a fresh node instance) — the fetch happens once
  when the node is created.
- Text fields are plain editable widgets: you can type/delete by hand in
  addition to using "Einfügen".

---

## Requirements

`PyYAML` in ComfyUI's Python environment. ComfyUI-Easy-Install's embedded
Python already ships it; if you're on a different ComfyUI setup and the
node fails to load, install it into that environment:

```
pip install pyyaml
```
