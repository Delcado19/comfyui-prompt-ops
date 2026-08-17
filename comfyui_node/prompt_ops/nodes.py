"""ComfyUI adapter node for the comfyui-prompt-ops snippet library.

Read-only: this node never writes to library/prompt_library.yml. Edit
snippets via the admin UI or by hand, then re-run scripts/dev.ps1 as usual.
The Espanso snippets and this node both read the same source of truth, they
just expand it in different places (system-wide text vs. a ComfyUI graph).
"""

import os

import yaml

_CONFIG_FILENAME = "library_path.txt"


def _library_path():
    config_file = os.path.join(os.path.dirname(__file__), _CONFIG_FILENAME)

    if not os.path.isfile(config_file):
        raise FileNotFoundError(
            f"{_CONFIG_FILENAME} not found next to nodes.py. "
            "Run scripts/install_comfy_node.ps1 from comfyui-prompt-ops to "
            "(re-)install this node instead of copying the folder by hand."
        )

    with open(config_file, "r", encoding="utf-8") as handle:
        path = handle.read().strip()

    if not path or not os.path.isfile(path):
        raise FileNotFoundError(
            f"library_path.txt points at a missing file: '{path}'. "
            "Re-run scripts/install_comfy_node.ps1."
        )

    return path


def _load_options():
    """Returns {combo_label: snippet_text} across all categories, freshly
    read from disk so admin/library edits apply without a ComfyUI restart
    (renamed/added/removed triggers still need a restart to show up in the
    dropdown, since ComfyUI caches INPUT_TYPES per session)."""
    with open(_library_path(), "r", encoding="utf-8") as handle:
        library = yaml.safe_load(handle) or {}

    options = {}
    for category in library.get("categories", []):
        label = category.get("label", category.get("id", "?"))
        for snippet in category.get("snippets", []):
            trigger = snippet.get("trigger")
            text = snippet.get("text")
            if not trigger or not text:
                continue
            options[f"[{label}] {trigger}"] = text

    return options


class PromptOpsSnippet:
    """Dropdown over every comfyui-prompt-ops snippet trigger, output as STRING."""

    @classmethod
    def INPUT_TYPES(cls):
        try:
            options = _load_options()
        except FileNotFoundError as error:
            # Surface the setup problem as a selectable option instead of
            # crashing ComfyUI's node listing.
            return {"required": {"snippet": ([str(error)],)}}

        labels = sorted(options.keys()) or ["(no snippets found)"]
        return {"required": {"snippet": (labels,)}}

    RETURN_TYPES = ("STRING",)
    RETURN_NAMES = ("text",)
    FUNCTION = "get_text"
    CATEGORY = "Prompt Ops"

    def get_text(self, snippet):
        options = _load_options()
        if snippet not in options:
            raise KeyError(
                f"'{snippet}' is no longer in library/prompt_library.yml. "
                "Reload/restart ComfyUI to refresh the dropdown."
            )
        return (options[snippet],)

    @classmethod
    def IS_CHANGED(cls, snippet):
        # Force re-execution when the library file changes on disk, even if
        # the selected dropdown value didn't, so edited snippet text doesn't
        # get served from ComfyUI's node cache.
        try:
            return os.path.getmtime(_library_path())
        except FileNotFoundError:
            return float("nan")
