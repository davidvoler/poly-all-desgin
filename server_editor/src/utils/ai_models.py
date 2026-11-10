"""The AI providers and models the editor's chat can pick from."""
import os

import httpx
from pydantic import BaseModel

from prompts.providers import ollama_base_url


class AiProvider(BaseModel):
    provider: str  # the name prompts.providers.get_provider takes
    label: str
    models: list[str]
    available: bool
    reason: str | None = None  # why the provider is not available


# The first model of each provider is its default. Edit to offer other models.
_HOSTED = [
    ("gemini", "Google Gemini", ("GOOGLE_API_KEY", "GEMINI_API_KEY"),
     ["gemini-2.5-flash", "gemini-flash-latest", "gemini-flash-lite-latest", "gemini-2.5-pro",
      "gemini-3.1-pro-preview"]),
    ("claude", "Anthropic Claude", ("ANTHROPIC_API_KEY",),
     ["claude-sonnet-5-5", "claude-haiku-5-5", "claude-opus-5-5"]),
    ("openai", "OpenAI", ("OPENAI_API_KEY",),
     ["gpt-5.4-mini", "gpt-5.5", "gpt-5.4-nano"]),
]


async def _ollama() -> AiProvider:
    """Ollama's installed models, or unavailable when it does not answer."""
    try:
        async with httpx.AsyncClient(timeout=2) as client:
            response = await client.get(ollama_base_url() + "/api/tags")
            response.raise_for_status()
        models = [m["name"].removesuffix(":latest") for m in response.json().get("models", [])]
        return AiProvider(provider="ollama", label="Ollama (local)", models=models,
                          available=bool(models), reason=None if models else "No models installed")
    except Exception:
        return AiProvider(provider="ollama", label="Ollama (local)", models=[], available=False,
                          reason="Ollama is not reachable")


async def ai_providers() -> list[AiProvider]:
    providers = [
        AiProvider(
            provider=name, label=label, models=models,
            available=any(os.getenv(key) for key in keys),
            reason=None if any(os.getenv(key) for key in keys) else f"{keys[0]} is not set",
        )
        for name, label, keys, models in _HOSTED
    ]
    return providers + [await _ollama()]
