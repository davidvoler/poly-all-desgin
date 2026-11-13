import random

from pydantic import BaseModel, Field
from pydantic_ai import Agent
from prompts.providers import get_provider
from utils.ai_utils import get_ai_model
from utils.context_options import EXERCISES_PER_WORD

class SingleChoice(BaseModel):
    sentence: str = Field(description="The target sentence containing a blank or question context.")
    incorrect_options: list[str] = Field(description="List of 3 plausible but incorrect options for the user to choose from.")
    translation: str = Field(description="Native translation of the full target sentence.")

class SingleChoiceList(BaseModel):
    questions: list[SingleChoice] = Field(description="A list of generated single-choice questions.")

async def get_single_choice(
    word: str,
    num_sentences: int = 3,
    provider: str = "gemini",
    model: str = "gemini-3.5-flash") -> SingleChoiceList:
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
    provider: str = "gemini",
    model: str = "gemini-3.5-flash") -> WordExerciseList:
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
WRONG_TRANSLATIONS = 3

# The highest similarity, in percent, a wrong translation may have to the correct one,
# by course level. Each wrong translation gets a random similarity from 0 up to this,
# so higher levels get wrong options closer to the correct one.
WRONG_OPTION_MAX_SIMILARITY = {"a1": 40, "a2": 50, "b1": 60, "b2": 70, "c1": 80, "c2": 90}
DEFAULT_MAX_SIMILARITY = 40


def wrong_option_similarities(level: str | None, count: int = WRONG_TRANSLATIONS) -> list[int]:
    """Random target similarities (percent, rounded to 5) for [count] wrong translations
    at this level, highest first."""
    top = WRONG_OPTION_MAX_SIMILARITY.get((level or "").strip().lower(), DEFAULT_MAX_SIMILARITY)
    return sorted((round(random.randint(0, top) / 5) * 5 for _ in range(count)), reverse=True)


class SentenceTranslationQuestion(BaseModel):
    """One single-choice question: a text in the learned language and its translations."""
    word: str = Field(description="The word this question practises, spelled exactly as given.")
    sentence: str = Field(description="The text in the learned language.")
    translation: str = Field(description="The correct translation of the text in the student's language.")
    incorrect_translations: list[str] = Field(
        description=f"{WRONG_TRANSLATIONS} wrong translations in the student's language.")

class SentenceTranslationQuestionList(BaseModel):
    questions: list[SentenceTranslationQuestion]


class WordStep(BaseModel):
    text: str = Field(description="The text in the learned language for this step.")
    translation: str = Field(description="Its correct translation in the student's language.")
    incorrect_translations: list[str] = Field(
        description=f"{WRONG_TRANSLATIONS} wrong translations in the student's language, each as similar to "
                    "the correct translation as the target given for this word and step.")

class WordSteps(BaseModel):
    word: str = Field(description="The word from the given list, spelled exactly as given.")
    steps: list[WordStep] = Field(
        description=f"Exactly {EXERCISES_PER_WORD} steps, in this order: 1. the word alone; 2. a short phrase "
                    "with the word (2-3 words); 3. the shortest natural sentence with the word; 4. a slightly "
                    "longer sentence with the word, at most 6 words.")

class WordStepsList(BaseModel):
    words: list[WordSteps] = Field(description="One entry per given word.")

async def get_single_choice_for_words(
    words: list[str],
    lang: str,
    to_lang: str,
    level: str,
    provider: str = "gemini",
    model: str = "gemini-3.5-flash") -> SentenceTranslationQuestionList:
    """EXERCISES_PER_WORD single-choice questions per word, from easy to harder: the word,
    a short phrase, a short sentence, and a sentence of at most 6 words. Each has its
    correct translation and wrong translations to choose from. Returned word by word,
    each word's steps in order."""
    agent = Agent(
        get_ai_model(provider, model),
        output_type=WordStepsList,
        system_prompt=f"You are an expert {lang} language teacher writing exercises for {level} learners who speak {to_lang}.",
    )
    # Target similarities for each word's steps, random within the level's range.
    targets = "\n".join(
        f"{word}: " + "; ".join(
            f"step {n}: " + ", ".join(f"{t}%" for t in wrong_option_similarities(level))
            for n in range(1, EXERCISES_PER_WORD + 1))
        for word in words)
    result = await agent.run(
        f"For each of these {lang} words: {', '.join(words)}, write {EXERCISES_PER_WORD} steps that build up "
        f"from the word alone to a short sentence:\n"
        f"1. The word alone.\n"
        f"2. A short phrase with the word, such as the word with an adjective or article (2-3 words).\n"
        f"3. The shortest natural sentence with the word.\n"
        f"4. A slightly longer sentence with the word, at most 6 words.\n"
        f"Example for the English word \"coffee\": coffee / hot coffee / The coffee is cold / I never drink coffee.\n"
        f"Keep the {lang} simple and common. For each step give its correct {to_lang} translation and "
        f"{WRONG_TRANSLATIONS} wrong {to_lang} translations.\n\n"
        f"Each wrong translation must read naturally, have about the same length as the correct one, and be "
        f"wrong. Make each one as similar to the correct translation as its target below. Similarity is how much "
        f"of the correct translation's words and meaning it keeps: 0% shares nothing (a different text on "
        f"another topic), 50% keeps about half, 100% would be the same text. Write them in the order given.\n"
        f"{targets}"
    )
    return SentenceTranslationQuestionList(questions=[
        SentenceTranslationQuestion(word=w.word, sentence=step.text, translation=step.translation,
                                    incorrect_translations=step.incorrect_translations)
        for w in result.output.words
        for step in w.steps[:EXERCISES_PER_WORD]
    ])


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
    provider: str = "gemini",
    model: str = "gemini-3.5-flash") -> dict[int, list[str]]:
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
