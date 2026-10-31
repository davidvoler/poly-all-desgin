import json
import logging
from utils.ollama_simple import get_ollama_response, get_ollama_response_system
from utils.lang_utils import get_language_name

from pydantic import BaseModel, RootModel

logger = logging.getLogger(__name__)


# Response schema for the quiz-item generator. The model returns a bare
# JSON array of these; `QuizList` is what we hand Ollama as `format=` so
# decoding is grammar-constrained to the right shape.
class QuizItem(BaseModel):
    sentence: str          # in the source language (`lang`)
    translation: str       # in the target language (`to_lang`)
    wrong_options: list[str]  # all in the target language (`to_lang`)

class QuizList(RootModel[list[QuizItem]]):
    pass

async def generate_ai_words(lang: str, to_lang: str, words_so_far: list, level: str, provider: str, model: str, max_words: int) -> list:
    """Generate a list of words using Ollama."""
    prompt = (
        f"""
           Create a list of {max_words} words in {get_language_name(lang)} that are appropriate for a {level} learner
           Respond with ONLY a JSON array, no prose, no markdown fences, in this exact shape:
           ["word1","word2"]
        """
    )
    logger.info(f"Prompt for Ollama: {prompt}")
    response = await get_ollama_response(prompt=prompt, model=model)
    return json.loads(response)



async def generate_ai_sentences(lang: str, to_lang: str, 
                                word: str, level: str, 
                                provider: str, model: str, 
                                max_words: int,num_sentences: int) -> list:
    """Generate a list of sentences for a given language and level using the specified method and provider.
        method: ai, corpus
        provider: openai, ollama
        model: model name or identifier
        max_words: maximum number of words per sentence
        num_sentences: number of sentences to generate
    """

    prompt = (
        f"""
        Create {num_sentences} sentences in {get_language_name(lang)} that are appropriate for a {level} learner
        using the word '{word}'.
        The maximum number of words per sentence should be {max_words}.
        Respond with ONLY a JSON array, no prose, no markdown fences, in this exact shape:
        ["sentence1","sentence2"]
        """
    )
    logger.info(f"Prompt for Ollama: {prompt}")
    response = await get_ollama_response(prompt=prompt, model=model)
    return json.loads(response)



async def generate_ai_translated_sentence_distractors(lang: str, 
                                                      to_lang: str, 
                                                      word: str, 
                                                      level: str, 
                                                      provider: str, 
                                                      model: str, 
                                                      max_words: int, 
                                                      num_sentences: int) -> list:


    src_name = get_language_name(lang)      # e.g. "Arabic"
    tgt_name = get_language_name(to_lang)   # e.g. "English"

    system_prompt = f"""
You are an expert {src_name} teacher writing multiple-choice quiz items for a {level} learner.

For the target word the user gives, produce {num_sentences} items. Each item has three fields:
- "sentence"      : one natural sentence in {src_name} using the target word, max {max_words} words.
- "translation"   : the correct translation of that sentence, written in {tgt_name}.
- "wrong_options" : exactly 4 WRONG translations of that sentence, every one written in {tgt_name}.
                    2 should be subtly wrong (one word or tense off), 2 clearly wrong.
                    Each is a full sentence, distinct from "translation" and from each other.

LANGUAGE RULES (strict):
- "sentence" is the ONLY field in {src_name}.
- "translation" and EVERY string in "wrong_options" must be in {tgt_name}. Never write {src_name} there.

Output ONLY a JSON array, no prose, no markdown fences, exactly this shape:
[{{"sentence": "<sentence in {src_name}>", "translation": "<sentence in {tgt_name}>", "wrong_options": ["<{tgt_name}>", "<{tgt_name}>", "<{tgt_name}>", "<{tgt_name}>"]}}]

Before answering, re-read each "wrong_options" string. If any is not written in {tgt_name}, rewrite it in {tgt_name}.
""".strip()
    user_prompt = (
        f"Target word (in {src_name}): '{word}'.\n"
        f"Reminder: 'translation' and all 'wrong_options' must be written in {tgt_name}."
    )
    logger.info(f"System prompt for Ollama: {system_prompt}")
    logger.info(f"User prompt for Ollama: {user_prompt}")
    response = await get_ollama_response_system(
        system_prompt=system_prompt, user_prompt=user_prompt, model=model, response_model=QuizList
    )
    logger.info(f"Response from Ollama: {response}")
    items = json.loads(response)
    # Downstream (routers/generate_poc_*.py, and the corpus path) read the
    # key `distractors` — keep that contract, the model just calls them
    # "wrong_options" because it follows that instruction better.
    for it in items:
        if isinstance(it, dict) and "wrong_options" in it:
            it.setdefault("distractors", it.pop("wrong_options"))
    return items
