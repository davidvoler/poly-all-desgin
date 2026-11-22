from pydantic import BaseModel, Field
from pydantic_ai import Agent, ModelRetry, RunContext

from prompts.course_instructions import course_instructions
from prompts.providers import get_provider

# Short sentences are easier for learners to read, hear and repeat.
MAX_SENTENCE_WORDS = 8


class Clause(BaseModel):
    text: str = Field(description="A clause within the sentence.")
    translation: str = Field(description="Native translation of the clause.")
class Sentence(BaseModel):
    text: str = Field(
        description=f"A short, simple, complete sentence of at most {MAX_SENTENCE_WORDS} words. "
                    "Either a short sentence from the text, or a new simpler sentence built from "
                    "the words of a long one.")
    translation: str = Field(description="Native translation of the full sentence.")
class Paragraph(BaseModel):
    text: str = Field(description="A full paragraph.")
    translation: str = Field(description="Native translation of the full paragraph.")
class Word(BaseModel):
    text: str = Field(description="A single word.")
    translation: str = Field(description="Native translation of the word.")


class TextParts(BaseModel):
    clauses: list[Clause] = Field(description="A list of clauses within the sentence.")
    sentences: list[Sentence] = Field(
        description=f"A list of short sentences, each at most {MAX_SENTENCE_WORDS} words.")
    paragraphs: list[Paragraph] = Field(description="A list of full paragraphs.")
    words: list[Word] = Field(description="A list of single words.")


def _word_count(text: str) -> int:
    # Counts space-separated words; languages written without spaces count as one
    # word and are left to the prompt.
    return len(text.split())


def _sentence_rules(language: str) -> str:
    return f"""
Sentences:
- Every sentence must be at most {MAX_SENTENCE_WORDS} words. Shorter is better.
- Keep a sentence from the text as it is when it is already short.
- When a sentence in the text is longer, do not copy it. Write one or more new, simpler
  {language} sentences instead, using the words of the long sentence or a part of it,
  so that together they keep its meaning and its vocabulary.
- Each new sentence must be complete, natural and grammatically correct on its own.
- Use simple grammar: one idea per sentence, avoid subordinate clauses.
"""


async def get_text_parts(
    language: str,
    to_language: str,
    text: str,
    level: str,
    provider: str = "gemini",
    model: str = "gemini-3.5-flash") -> TextParts:
    model_instance = get_provider(provider, model)
    agent = Agent(
        model_instance,
        instructions=course_instructions() + _sentence_rules(language),
        output_type=TextParts,
        output_retries=2,
        system_prompt=f"You are an expert language teacher. You are creating {language} learning materials for {level} learners.")

    @agent.output_validator
    def _short_sentences(ctx: RunContext[None], output: TextParts) -> TextParts:
        long = [s.text for s in output.sentences if _word_count(s.text) > MAX_SENTENCE_WORDS]
        if not long:
            return output
        if ctx.retry < ctx.max_retries:
            raise ModelRetry(
                f"These sentences are longer than {MAX_SENTENCE_WORDS} words: {long}. "
                "Replace each with shorter, simpler sentences that use its words.")
        # Out of retries: drop the long sentences rather than fail the request.
        output.sentences = [s for s in output.sentences if s.text not in long]
        return output

    result = await agent.run(f"Break the following text language: {language} into clauses, sentences, paragraphs, and words: {text} use native translations for each part from {language} to {to_language}. ")
    return result.output
