"""ComfyUI adapter node for the comfyui-prompt-ops snippet library.

Read-only: this node never writes to library/prompt_library.yml. Edit
snippets via the admin UI or by hand, then re-run scripts/dev.ps1 as usual.
The category/entry data is served to the node's JS widget via a small
aiohttp route (/prompt_ops/library) because Python's INPUT_TYPES can't
drive the dependent-filter + insert-button UI this node needs -- see
js/prompt_ops_browser.js for the client-side logic.
"""

import os

import yaml
from aiohttp import web
from server import PromptServer

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


def _load_categories():
    """[{id, label, polarity, entries: [{trigger, text}]}], freshly read
    from disk on every request. "Negative" is the only negative-polarity
    category; everything else is positive. Negative-polarity entries can
    still be routed to the positive output client-side, for workflows
    (e.g. zero-out conditioning) that only have a single prompt input."""
    with open(_library_path(), "r", encoding="utf-8") as handle:
        library = yaml.safe_load(handle) or {}

    categories = []
    for category in library.get("categories", []):
        label = category.get("label", category.get("id", "?"))
        entries = [
            {"trigger": snippet["trigger"], "text": snippet["text"]}
            for snippet in category.get("snippets", [])
            if snippet.get("trigger") and snippet.get("text")
        ]
        if not entries:
            continue
        categories.append(
            {
                "id": category.get("id", label),
                "label": label,
                "polarity": "negative" if label == "Negative" else "positive",
                "entries": entries,
            }
        )
    return categories


@PromptServer.instance.routes.get("/prompt_ops/library")
async def get_prompt_ops_library(_request):
    try:
        return web.json_response(_load_categories())
    except FileNotFoundError as error:
        return web.json_response({"error": str(error)}, status=404)


class PromptOpsBrowser:
    """Category/polarity-filterable snippet browser with an insert button.
    positive_text/negative_text are plain editable multiline widgets that
    the JS side appends to; this class just passes their values through as
    outputs for CLIP Text Encode (or similar) nodes downstream."""

    @classmethod
    def INPUT_TYPES(cls):
        return {
            "required": {
                "positive_text": ("STRING", {"multiline": True, "default": ""}),
                "negative_text": ("STRING", {"multiline": True, "default": ""}),
            }
        }

    RETURN_TYPES = ("STRING", "STRING")
    RETURN_NAMES = ("positive", "negative")
    FUNCTION = "get_text"
    CATEGORY = "Prompt Ops"

    def get_text(self, positive_text, negative_text):
        return (positive_text, negative_text)
