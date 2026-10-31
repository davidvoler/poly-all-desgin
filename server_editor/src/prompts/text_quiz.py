'''Quiz text parts for language learning.'''
from pydantic import BaseModel, Field
from pydantic_ai import Agent
from prompts.providers import get_provider


class Clause(BaseModel):
    text: str = Field(description="A clause within the sentence.")
    translation: str = Field(description="Native translation of the clause.")
class Sentence(BaseModel):
    text: str = Field(description="A full sentence.")
    translation: str = Field(description="Native translation of the full sentence.")
class Paragraph(BaseModel):
    text: str = Field(description="A full paragraph.")
    translation: str = Field(description="Native translation of the full paragraph.")
class Word(BaseModel):
    text: str = Field(description="A single word.")
    translation: str = Field(description="Native translation of the word.")


class TextParts(BaseModel):
    clauses: list[Clause] = Field(description="A list of clauses within the sentence.")
    sentences: list[Sentence] = Field(description="A list of full sentences.")
    paragraphs: list[Paragraph] = Field(description="A list of full paragraphs.")
    words: list[Word] = Field(description="A list of single words.")

async def get_text_quiz(
    language: str,
    to_language: str,
    text: str,
    level: str,
    provider: str = "ollama",
    model: str = "llama3.1") -> TextParts:
    model_instance = get_provider(provider, model)
    agent = Agent(
        model_instance,
        output_type=TextParts,
        system_prompt=f"You are an expert language teacher. You are creating {language} learning materials for {level} learners.")
    result = await agent.run(f"Break the following text language: {language} into clauses, sentences, paragraphs, and words: {text} use native translations for each part from {language} to {to_language}. ")
    return result.output