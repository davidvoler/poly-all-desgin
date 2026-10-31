from pydantic import BaseModel, Field
from pydantic_ai import Agent
from prompts.providers import get_provider
from utils.ai_utils import get_ai_model

class SingleChoice(BaseModel):
    sentence: str = Field(description="The target sentence containing a blank or question context.")
    incorrect_options: list[str] = Field(description="List of 3 plausible but incorrect options for the user to choose from.")
    translation: str = Field(description="Native translation of the full target sentence.")

class SingleChoiceList(BaseModel):
    questions: list[SingleChoice] = Field(description="A list of generated single-choice questions.")

async def get_single_choice(
    word: str,
    num_sentences: int = 3,
    provider: str = "ollama",
    model: str = "llama3.1") -> SingleChoiceList:
    model_instance = get_provider(provider, model)
    agent = Agent(
        model_instance,
        output_type=SingleChoiceList,
        system_prompt="You are an expert language teacher.",)
    result = await agent.run(f"Create {num_sentences} questions for the word: {word}")
    return result.output

class WordExercise(BaseModel):
    word: str = Field(description="The word from the given list that this question practises, spelled exactly as given.")
    sentence: str = Field(description="A short sentence in the learned language with ___ where the word goes.")
    incorrect_options: list[str] = Field(description="3 plausible but incorrect words for the blank.")
    translation: str = Field(description="Translation of the full sentence, with the word filled in, in the student's language.")

class WordExerciseList(BaseModel):
    exercises: list[WordExercise] = Field(description="One question per given word.")

async def get_fill_in_blank_for_words(
    words: list[str],
    lang: str,
    to_lang: str,
    level: str,
    provider: str = "ollama",
    model: str = "llama3.1") -> WordExerciseList:
    """One fill-in-the-blank question per word (the word is the answer), in one AI call."""
    agent = Agent(
        get_ai_model(provider, model),
        output_type=WordExerciseList,
        system_prompt=f"You are an expert {lang} language teacher writing exercises for {level} learners who speak {to_lang}.",
    )
    result = await agent.run(
        f"Write one fill-in-the-blank question for each of these {lang} words: {', '.join(words)}. "
        f"Each question is a short {lang} sentence with ___ in place of the word."
    )
    return result.output



# Wrong translations offered with each single-choice sentence.
WRONG_TRANSLATIONS = 4


class SentenceTranslationQuestion(BaseModel):
    word: str = Field(description="The word from the given list that this question practises, spelled exactly as given.")
    sentence: str = Field(description="A short sentence in the learned language that uses the word.")
    translation: str = Field(description="The correct translation of the whole sentence in the student's language.")
    incorrect_translations: list[str] = Field(
        description=f"{WRONG_TRANSLATIONS} wrong translations of the sentence in the student's language: "
                    "plausible, similar sentences whose meaning differs from the original.")

class SentenceTranslationQuestionList(BaseModel):
    questions: list[SentenceTranslationQuestion] = Field(description="One question per given word.")

async def get_single_choice_for_words(
    words: list[str],
    lang: str,
    to_lang: str,
    level: str,
    provider: str = "ollama",
    model: str = "llama3.1") -> SentenceTranslationQuestionList:
    """One single-choice question per word: a sentence in the learned language that
    uses the word, its correct translation, and wrong translations to choose from."""
    agent = Agent(
        get_ai_model(provider, model),
        output_type=SentenceTranslationQuestionList,
        system_prompt=f"You are an expert {lang} language teacher writing exercises for {level} learners who speak {to_lang}.",
    )
    result = await agent.run(
        f"Write one single-choice question for each of these {lang} words: {', '.join(words)}. "
        f"For each word, write a short {lang} sentence that uses it, its correct {to_lang} translation, "
        f"and {WRONG_TRANSLATIONS} wrong {to_lang} translations. Each wrong translation must read naturally "
        f"and look like the correct one, but change the meaning (for example a different word, person, "
        f"tense or negation), so only a learner who understands the {lang} sentence picks the right one."
    )
    return result.output


class SentenceWrongTranslations(BaseModel):
    number: int = Field(description="The number of the sentence in the given list.")
    incorrect_translations: list[str] = Field(description="Wrong translations of that sentence.")

class SentenceWrongTranslationsList(BaseModel):
    sentences: list[SentenceWrongTranslations] = Field(description="One entry per given sentence.")

async def get_wrong_translations(
    sentences: list[tuple[str, str]],
    lang: str,
    to_lang: str,
    count: int = 3,
    provider: str = "ollama",
    model: str = "llama3.1") -> dict[int, list[str]]:
    """Wrong translations for each (sentence, correct translation), by the sentence's
    position in the list: alike in form, different in meaning."""
    listing = "\n".join(f"{i}. {s} => {t}" for i, (s, t) in enumerate(sentences, start=1))
    agent = Agent(
        get_ai_model(provider, model),
        output_type=SentenceWrongTranslationsList,
        system_prompt=f"You are an expert {lang} language teacher writing single-choice exercises for students who speak {to_lang}.",
    )
    result = await agent.run(
        f"Each line is a numbered {lang} sentence and its correct {to_lang} translation:\n{listing}\n\n"
        f"For each sentence, write {count} wrong {to_lang} translations. Each must read naturally and look like "
        f"the correct one, but change the meaning (for example a different word, person, tense or negation)."
    )
    return {s.number: s.incorrect_translations[:count] for s in result.output.sentences}
