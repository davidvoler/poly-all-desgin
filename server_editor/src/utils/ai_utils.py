from prompts.providers import get_provider

def get_ai_model(provider: str = "gemini", model: str = "gemini-2.5-flash"):
    return get_provider(provider, model)


