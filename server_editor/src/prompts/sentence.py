from pydantic import BaseModel, Field
from pydantic_ai import Agent
from prompts.providers import get_provider

class SentenceTranslation(BaseModel):
    sentence: str = Field(description="The target sentence containing a blank or question context.")
    incorrect_options: list[str] = Field(description="List of 3 plausible but incorrect options for the user to choose from.")
    translation: str = Field(description="Native translation of the full target sentence.")

class SentenceTranslationList(BaseModel):
    questions: list[SentenceTranslation] = Field(description="A list of generated sentence translations.")

async def get_sentence_translation(
    word: str,
    num_sentences: int = 3,
    provider: str = "ollama",
    model: str = "llama3.1") -> SentenceTranslationList:
    """Generate a list of sentence translation questions for the given word."""
    model_instance = get_provider(provider, model)
    agent = Agent(
        model_instance,
        output_type=SentenceTranslationList,
        system_prompt="You are an expert language teacher.",)
    result = await agent.run(f"Create {num_sentences} questions for the word: {word}")
    return result.output