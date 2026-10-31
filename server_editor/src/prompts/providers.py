import os


def get_provider(provider: str="ollama", model: str="llama3.1"):
    if provider == "ollama":
        from pydantic_ai.models.ollama import OllamaModel
        from pydantic_ai.providers.ollama import OllamaProvider

        return OllamaModel(
            model_name=model,
            provider=OllamaProvider(
                base_url=os.getenv("OLLAMA_BASE_URL", "http://localhost:11434/v1")
            ),
        )
    elif provider == "openai":
        from pydantic_ai.models.openai import OpenAIModel

        return OpenAIModel(model_name=model)
    elif provider == "gemini":
        from pydantic_ai.models.gemini import GeminiModel

        return GeminiModel(model_name=model)
    elif provider == "claude":
        from pydantic_ai.models.claude import ClaudeModel

        return ClaudeModel(model_name=model)
    else:
        raise ValueError(f"Unsupported provider: {provider}")

