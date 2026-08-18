from .nodes import PromptOpsBrowser

NODE_CLASS_MAPPINGS = {
    "PromptOpsBrowser": PromptOpsBrowser,
}

NODE_DISPLAY_NAME_MAPPINGS = {
    "PromptOpsBrowser": "Prompt Ops Browser",
}

WEB_DIRECTORY = "./js"

__all__ = ["NODE_CLASS_MAPPINGS", "NODE_DISPLAY_NAME_MAPPINGS", "WEB_DIRECTORY"]
