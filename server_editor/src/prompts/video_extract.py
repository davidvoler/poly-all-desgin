from pydantic import BaseModel, Field
from pydantic_ai import Agent

from models.word import WordTranslation
from utils.ai_utils import get_ai_model

# Upper bounds asked of the model per video part, to keep each call short.
WORDS_PER_PART = 15
SENTENCES_PER_PART = 10


class SentenceTranslation(BaseModel):
    sentence: str = Field(description="A complete, cleaned-up sentence from the text, in the learned language.")
    translation: str = Field(description="Translation of the sentence in the student's language.")


class PartExtract(BaseModel):
    words: list[WordTranslation] = Field(description="Words from the text worth learning, with translations.")
    sentences: list[SentenceTranslation] = Field(description="Useful sentences from the text, with translations.")


async def extract_from_part(
    text: str,
    lang: str,
    to_lang: str,
    level: str,
    provider: str = "ollama",
    model: str = "llama3.1") -> PartExtract:
    """Words and sentences worth learning from one part of a video's subtitles."""
    agent = Agent(
        get_ai_model(provider, model),
        output_type=PartExtract,
        system_prompt=f"You are an expert {lang} language teacher preparing {level} lessons for students who speak {to_lang}.",
    )
    result = await agent.run(
        f"These are subtitles from part of a {lang} video:\n\n{text}\n\n"
        f"List up to {WORDS_PER_PART} {lang} words from them that a {level} learner should learn, "
        f"in their dictionary form, each with its {to_lang} translation. "
        f"Then list up to {SENTENCES_PER_PART} complete sentences from the subtitles "
        f"(join fragments, fix punctuation, skip music and sound notes), each with its {to_lang} translation."
    )
    return result.output
