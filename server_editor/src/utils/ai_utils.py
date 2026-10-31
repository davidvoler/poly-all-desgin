from pydantic_ai.models.ollama import OllamaModel
from pydantic_ai.models.openai import OpenAIChatModel
# from pydantic_ai.models.gemini import GeminiModel
# from pydantic_ai.models.claude import ClaudeModel
import os 

def get_ai_model(provider: str="ollama", model: str="llama3.1"):
    print(f"Getting AI model for provider: {provider}, model: {model} {os.getenv('OLLAMA_BASE_URL', 'http://localhost:11434/v1')}")
    if provider == "ollama":
        return OllamaModel(
            model_name=model
        )
    elif provider == "openai":
        return OpenAIChatModel(model_name=model)
    # elif provider == "gemini":
    #     return GeminiModel(model_name=model)
    # elif provider == "claude":
    #     return ClaudeModel(model_name=model)
    else:
        raise ValueError(f"Unsupported provider: {provider}")


