# Prompt Library Admin

The prompt library admin is a local web interface for editing prompt categories and snippets.

Start it from the repository root:

```powershell
npm run admin
```

Then open:

```text
http://127.0.0.1:5177
```

## Source Of Truth

The admin edits:

```text
library/prompt_library.yml
```

The Espanso snippet files are generated output:

```text
snippets/comfy_*.yml
snippets/zz_prompt_builder.yml
docs/snippets.md
```

Do not manually edit generated `snippets/comfy_*.yml` files when using the admin workflow. Edit the library instead, then generate outputs.

## Actions

- `Save` writes `library/prompt_library.yml`.
- `Generate` writes Espanso snippets, validates them, regenerates the prompt builder, and updates snippet documentation.
- `Install` copies generated snippets to the Espanso match directory.

## Naming

Use lowercase ids with underscores:

```text
model_zit_jibmix
moonlit_garden
lowkey_latex
```

Triggers use the category prefix:

```text
:model_zit_jibmix
:scene_moonlit_garden
:light_lowkey_latex
```

The admin normalizes ids and checks for duplicate triggers before saving.
