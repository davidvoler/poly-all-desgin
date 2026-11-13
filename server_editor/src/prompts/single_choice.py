import random
import unicodedata

from pydantic import BaseModel, Field
from pydantic_ai import Agent

from prompts.course_instructions import course_instructions
from prompts.providers import get_provider
from utils.ai_utils import get_ai_model
from utils.context_options import EXERCISES_PER_WORD
from utils.exercise_utils import option_key, strip_diacritics

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
        instructions=course_instructions(),
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
        instructions=course_instructions(),
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
WRONG_OPTION_MAX_SIMILARITY = {"a1": 25, "a2": 30, "b1": 35, "b2": 40, "c1": 50, "c2": 60}
DEFAULT_MAX_SIMILARITY = 30


def wrong_option_similarities(level: str | None, count: int = WRONG_TRANSLATIONS) -> list[int]:
    """Random target similarities (percent, rounded to 5) for [count] wrong translations
    at this level, highest first."""
    top = WRONG_OPTION_MAX_SIMILARITY.get((level or "").strip().lower(), DEFAULT_MAX_SIMILARITY)
    return sorted((round(random.randint(0, top) / 5) * 5 for _ in range(count)), reverse=True)


class SentenceTranslationQuestion(BaseModel):
    """One single-choice question: a text in the learned language and its translations."""
    word: str = Field(description="The word this question practises, spelled exactly as given.")
    sentence: str = Field(description="The text in the learned language.")
    # The same text with diacritics, when the course asks for them.
    sentence_with_diacritics: str | None = None
    translation: str = Field(description="The correct translation of the text in the student's language.")
    incorrect_translations: list[str] = Field(
        description=f"{WRONG_TRANSLATIONS} wrong translations in the student's language.")

class SentenceTranslationQuestionList(BaseModel):
    questions: list[SentenceTranslationQuestion]


class WordStep(BaseModel):
    text: str = Field(description="The text in the learned language for this step, without diacritics.")
    text_with_diacritics: str | None = Field(
        default=None, description="The same text with full diacritics (vowel marks), when asked for; else empty.")
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
    model: str = "gemini-3.5-flash",
    diacritics: bool = False) -> SentenceTranslationQuestionList:
    """EXERCISES_PER_WORD single-choice questions per word, from easy to harder: the word,
    a short phrase, a short sentence, and a sentence of at most 6 words. Each has its
    correct translation and wrong translations to choose from. Returned word by word,
    each word's steps in order. No text has diacritics; with [diacritics], each
    question also has its learned-language text with them."""
    agent = Agent(
        get_ai_model(provider, model),
        instructions=course_instructions(),
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
        f"{WRONG_TRANSLATIONS} wrong {to_lang} translations.\n"
        f"Write all texts and translations without diacritics (no vowel marks such as harakat or niqqud). "
        + (f"Also give each step's {lang} text again in text_with_diacritics, with full, correct diacritics.\n\n"
           if diacritics else "Leave text_with_diacritics empty.\n\n")
        + f"Each wrong translation must read naturally, have about the same length as the correct one, and be "
        f"wrong. Make each one as similar to the correct translation as its target below. Similarity is how much "
        f"of the correct translation's words and meaning it keeps: 0% shares nothing (a different text on "
        f"another topic), 50% keeps about half, 100% would be the same text. Write them in the order given.\n"
        f"Even at a high target, a wrong translation must mean something different from the correct one: "
        f"never the correct translation with only punctuation, capitalisation, spacing or vowel marks changed, "
        f"and never the same as another wrong translation.\n"
        f"{targets}"
    )
    questions = []
    for w in result.output.words:
        for step in w.steps[:EXERCISES_PER_WORD]:
            marked = _with_diacritics(step) if diacritics else None
            questions.append(SentenceTranslationQuestion(
                # From the marked text when there is one: it also has the hamza the
                # plain text sometimes leaves out.
                word=w.word, sentence=strip_diacritics(marked or step.text),
                sentence_with_diacritics=marked,
                translation=strip_diacritics(step.translation),
                incorrect_translations=_distinct_wrong(step.translation, step.incorrect_translations)))
    await _top_up_wrong_translations(questions, lang, to_lang, provider, model)
    return SentenceTranslationQuestionList(questions=questions)


def _bare(text: str) -> str:
    """The letters alone, without any combining mark (hamza and madda too), to check
    that two texts are the same words."""
    return "".join(c for c in unicodedata.normalize("NFD", text or "") if not unicodedata.category(c).startswith("M"))


def _with_diacritics(step: WordStep) -> str | None:
    """The step's text with diacritics, when the model gave it for the same words: its
    text_with_diacritics, else the text itself when that already has them."""
    marked = (step.text_with_diacritics or "").strip()
    if marked and strip_diacritics(marked) != marked and _bare(marked) == _bare(step.text):
        return marked
    if strip_diacritics(step.text) != step.text:
        return step.text
    return None


def _distinct_wrong(correct: str, wrong: list[str]) -> list[str]:
    """The wrong translations, without diacritics, that differ from the correct one and
    from each other, ignoring punctuation, case, spacing and vowel marks."""
    seen, kept = {option_key(correct)}, []
    for text in map(strip_diacritics, wrong):
        key = option_key(text)
        if key and key not in seen:
            seen.add(key)
            kept.append(text)
    return kept


async def _top_up_wrong_translations(questions: list[SentenceTranslationQuestion], lang: str, to_lang: str,
                                     provider: str, model: str) -> None:
    """Models sometimes return a wrong translation that is the correct one again, maybe
    without its full stop. Asks once more for the questions left with too few."""
    short = [q for q in questions if len(q.incorrect_translations) < WRONG_TRANSLATIONS]
    if not short:
        return
    extra = await get_wrong_translations(
        [(q.sentence, q.translation) for q in short], lang=lang, to_lang=to_lang,
        count=WRONG_TRANSLATIONS, provider=provider, model=model,
        avoid=[q.incorrect_translations for q in short])
    for number, q in enumerate(short, start=1):
        q.incorrect_translations = _distinct_wrong(
            q.translation, q.incorrect_translations + extra.get(number, []))[:WRONG_TRANSLATIONS]


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
    model: str = "gemini-3.5-flash",
    avoid: list[list[str]] | None = None) -> dict[int, list[str]]:
    """Wrong translations for each (sentence, correct translation), by the sentence's
    position in the list: alike in form, different in meaning. [avoid] gives, per
    sentence, wrong translations it already has, which are not to be repeated."""
    listing = "\n".join(
        f"{i}. {s} => {t}" + (f" (already used, do not repeat: {' | '.join(avoid[i - 1])})"
                               if avoid and i <= len(avoid) and avoid[i - 1] else "")
        for i, (s, t) in enumerate(sentences, start=1))
    agent = Agent(
        get_ai_model(provider, model),
        instructions=course_instructions(),
        output_type=SentenceWrongTranslationsList,
        system_prompt=f"You are an expert {lang} language teacher writing single-choice exercises for students who speak {to_lang}.",
    )
    result = await agent.run(
        f"Each line is a numbered {lang} sentence and its correct {to_lang} translation:\n{listing}\n\n"
        f"For each sentence, write {count} wrong {to_lang} translations. Each must read naturally and look like "
        f"the correct one, but change the meaning (for example a different word, person, tense or negation). "
        f"Never write the correct translation with only punctuation, capitalisation, spacing or vowel marks "
        f"changed, and never repeat a translation."
    )
    return {s.number: s.incorrect_translations[:count] for s in result.output.sentences}
