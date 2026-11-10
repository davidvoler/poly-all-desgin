"""The AI providers and models the editor's chat can pick from."""
import httpx
from pydantic import BaseModel

from prompts.providers import ollama_base_url
from utils.api_keys import key_sources


class AiProvider(BaseModel):
    provider: str  # the name prompts.providers.get_provider takes
    label: str
    models: list[str]
    available: bool
    reason: str | None = None  # why the provider is not available
    key_source: str | None = None  # user, school or server: whose key is used


# The first model of each provider is its default. Edit to offer other models.
_HOSTED = [
    ("gemini", "Google Gemini",
     # Google refuses the 2.5 models for new API keys. Pro models need a paid plan.
     ["gemini-3.5-flash", "gemini-3.6-flash", "gemini-3-flash-preview", "gemini-3.5-flash-lite",
      "gemini-3.1-flash-lite", "gemini-3.1-pro-preview"]),
    ("claude", "Anthropic Claude",
     ["claude-sonnet-5-5", "claude-haiku-5-5", "claude-opus-5-5"]),
    ("openai", "OpenAI",
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


async def ai_providers(school: str, user_id: int) -> list[AiProvider]:
    """Each provider is available when the user, their school or the server has a key."""
    sources = await key_sources(school, user_id)
    providers = [
        AiProvider(
            provider=name, label=label, models=models,
            available=name in sources, key_source=sources.get(name),
            reason=None if name in sources else "No API key: add one under AI keys",
        )
        for name, label, models in _HOSTED
    ]
    return providers + [await _ollama()]
