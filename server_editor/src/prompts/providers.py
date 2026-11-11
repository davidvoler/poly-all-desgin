import os
from contextlib import contextmanager
from contextvars import ContextVar

# The API keys of the school or user a prompt runs for, by provider. Set by
# use_api_keys for the length of a prompt task, so the prompt functions that
# call get_provider do not have to pass keys along.
_api_keys: ContextVar[dict[str, str] | None] = ContextVar("ai_api_keys", default=None)


class MissingApiKeyError(Exception):
    pass


@contextmanager
def use_api_keys(keys: dict[str, str]):
    token = _api_keys.set(keys)
    try:
        yield
    finally:
        _api_keys.reset(token)


def _api_key(provider: str) -> str:
    keys = _api_keys.get()
    if keys is None:
        # Outside a prompt task, such as a script or test: the server's own key.
        from utils.api_keys import env_key
        key = env_key(provider)
    else:
        key = keys.get(provider)
    if not key:
        raise MissingApiKeyError(
            f"No API key for {provider}. Add one for your school or yourself under AI keys.")
    return key


def ollama_base_url() -> str:
    """Ollama's address without the /v1 suffix of its OpenAI-compatible API."""
    url = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434").rstrip("/")
    return url.removesuffix("/v1")


def get_provider(provider: str = "gemini", model: str = "gemini-3.5-flash"):
    if provider == "ollama":
        from pydantic_ai.models.ollama import OllamaModel
        from pydantic_ai.providers.ollama import OllamaProvider

        # pydantic-ai uses Ollama's OpenAI-compatible API, which lives under /v1.
        return OllamaModel(
            model_name=model,
            provider=OllamaProvider(base_url=ollama_base_url() + "/v1"),
        )
    elif provider == "openai":
        from pydantic_ai.models.openai import OpenAIChatModel
        from pydantic_ai.providers.openai import OpenAIProvider

        return OpenAIChatModel(
            model_name=model, provider=OpenAIProvider(api_key=_api_key(provider)))
    elif provider == "gemini":
        from pydantic_ai.models.google import GoogleModel
        from pydantic_ai.providers.google import GoogleProvider

        return GoogleModel(
            model_name=model, provider=GoogleProvider(api_key=_api_key(provider)))
    elif provider == "claude":
        from pydantic_ai.models.anthropic import AnthropicModel
        from pydantic_ai.providers.anthropic import AnthropicProvider

        return AnthropicModel(
            model_name=model, provider=AnthropicProvider(api_key=_api_key(provider)))
    else:
        raise ValueError(f"Unsupported provider: {provider}")
