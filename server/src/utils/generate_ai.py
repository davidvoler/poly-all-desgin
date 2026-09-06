import json
from utils.ollama_simple import get_ollama_response, get_ollama_response_system
from utils.lang_utils import get_language_name

from pydantic import BaseModel

# 1. Define the response schema using Pydantic
class QuizItem(BaseModel):
    sentence: str
    translation: str
    distractors: list[str]

class QuizResponse(BaseModel):
    quiz: list[QuizItem]

async def generate_ai_words(lang: str, to_lang: str, words_so_far: list, level: str, provider: str, model: str, max_words: int) -> list:
    """Generate a list of words using Ollama."""
    prompt = (
        f"""
           Create a list of {max_words} words in {get_language_name(lang)} that are appropriate for a {level} learner
           Respond with ONLY a JSON array, no prose, no markdown fences, in this exact shape:
           ["word1","word2"]
        """
    )
    print(f"Prompt for Ollama: {prompt}")
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
    print(f"Prompt for Ollama: {prompt}")
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


    system_prompt = f"""
You are an expert language teacher creating quiz items.
Create {num_sentences} sentences in {get_language_name(lang)} appropriate for a {level} learner with the provided target word and translate them into {get_language_name(to_lang)}.
Maximum length: {max_words} words per sentence.
Include 4 incorrect translations (distractors) per sentence: a mix of subtle errors and completely wrong options.
Return ONLY valid data adhering to the required JSON schema.
""".strip()
    user_prompt = f"Target word: '{word}'"
    print(f"System prompt for Ollama: {system_prompt}")
    print(f"User prompt for Ollama: {user_prompt}")
    response = await get_ollama_response_system(system_prompt=system_prompt, user_prompt=user_prompt, model=model, response_model=QuizResponse)
    return json.loads(response)
