from pydantic_ai.models.ollama import OllamaModel
from pydantic_ai.models.openai import OpenAIModel
from pydantic_ai.models.gemini import GeminiModel
# from pydantic_ai.models.claude import ClaudeModel
import os 

def get_provider(provider: str="ollama", model: str="llama3.1"):
    if provider == "ollama":
        return OllamaModel(
            model_name=model,
            base_url=os.getenv("OLLAMA_BASE_URL", "http://localhost:11434/v1"),  # Matches your local Ollama instance
        )
    elif provider == "openai":
        return OpenAIModel(model_name=model)
    elif provider == "gemini":
        return GeminiModel(model_name=model)
    # elif provider == "claude":
    #     return ClaudeModel(model_name=model)
    else:
        raise ValueError(f"Unsupported provider: {provider}")

