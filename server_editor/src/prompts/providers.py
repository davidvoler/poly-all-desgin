import os


def ollama_base_url() -> str:
    """Ollama's address without the /v1 suffix of its OpenAI-compatible API."""
    url = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434").rstrip("/")
    return url.removesuffix("/v1")


def get_provider(provider: str = "gemini", model: str = "gemini-2.5-flash"):
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

        return OpenAIChatModel(model_name=model)
    elif provider == "gemini":
        from pydantic_ai.models.google import GoogleModel

        return GoogleModel(model_name=model)
    elif provider == "claude":
        from pydantic_ai.models.anthropic import AnthropicModel

        return AnthropicModel(model_name=model)
    else:
        raise ValueError(f"Unsupported provider: {provider}")

