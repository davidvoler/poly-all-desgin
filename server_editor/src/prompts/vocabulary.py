from pydantic import BaseModel, Field
from pydantic_ai import Agent
from prompts.providers import get_provider
from models.word import (WordTranslationList, WordTranslation)
from utils.ai_utils import get_ai_model


async def prompt_suggested_words(
   lang: str,
   to_lang: str,
   level: str,
   num_words: int = 30,
    provider: str = "ollama",
    model: str = "muse-glimmer") -> WordTranslationList:
    """Generate a list of words and their translations. for students speaking {to_lang} learning {lang}. """
    model_instance = get_ai_model(provider, model)
    system_prompt=f"You are an expert {lang} language teacher."
    print(system_prompt)
    prompt=f"Create {num_words} words in {lang} suitable for {level} learners and provide their translations in {to_lang}."
    print(prompt)
    agent = Agent(
        model_instance,
        output_type=WordTranslationList,
        system_prompt=system_prompt
    )

    result = await agent.run(prompt)
    return result.output