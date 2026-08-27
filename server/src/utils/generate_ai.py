import json
from utils.ollama_simple import get_ollama_response
from utils.lang_utils import get_language_name



async def generate_ai_words(lang: str, to_lang: str, words_so_far: list, level: str, model: str, max_words: int) -> list:
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



async def generate_ai_sentences(lang: str, to_lang: str, word: str, level: str, method: str, provider: str, model: str, max_words: int, num_sentences: int) -> list:
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



async def generate_ai_translated_sentence_distractors(lang: str, to_lang: str, word: str, level: str, method: str, provider: str, model: str, max_words: int, num_sentences: int) -> list:
    """Generate a list of sentences for a given language and level using the specified method and provider.
        method: ai, corpus
        provider: openai, ollama
        model: model name or identifier
        max_words: maximum number of words per sentence
        num_sentences: number of sentences to generate
    """
    

    prompt = f"""
                Create {num_sentences} sentences in {get_language_name(lang)} that are appropriate for a {level} learner with the word '{word}' and translate them into {get_language_name(to_lang)}.
                The sentences should be translated into {get_language_name(to_lang)} 
                The maximum number of words per sentence should be {max_words}.
                Also add incorrect translations - to be used as wrong answers in a quiz.
                The incorrect translations should be a mix of:
                - somewhat similar to the correct translations.
                - completely different from the correct translations.
                Respond with ONLY a JSON array, no prose, no markdown fences, in this exact shape:
                [{{"{lang}": "sentence1", "{to_lang}": "translation1", "distractors":["sentence1", "sentence2","sentence3"]}},]
                """
            
    print(f"Prompt for Ollama: {prompt}")
    response = await get_ollama_response(prompt=prompt, model=model)
    return json.loads(response)
