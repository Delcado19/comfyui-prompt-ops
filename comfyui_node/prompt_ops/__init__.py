from .nodes import PromptOpsSnippet

NODE_CLASS_MAPPINGS = {
    "PromptOpsSnippet": PromptOpsSnippet,
}

NODE_DISPLAY_NAME_MAPPINGS = {
    "PromptOpsSnippet": "Prompt Ops Snippet",
}

__all__ = ["NODE_CLASS_MAPPINGS", "NODE_DISPLAY_NAME_MAPPINGS"]
