import json
import re

# from utils.ollama_client import ollama_chat, OllamaError
from utils.ollama_simple import get_ollama_response
from utils.lang_utils import get_language_name



async def _get_words_ollama(lang: str, to_lang: str, words_so_far: list, level: str, model: str, max_words: int) -> list:
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


async def _get_words_openai(lang: str, to_lang: str, words_so_far: list, level: str, model: str, max_words: int) -> list:
    """Generate a list of words using OpenAI."""
    # Placeholder for OpenAI implementation
    raise NotImplementedError("OpenAI generation is not implemented yet.")


async def _get_words_zipf(lang: str, to_lang: str, words_so_far: list, level: str, model: str, max_words: int) -> list:
    """Generate a list of words using Zipf's law."""
    # Placeholder for Zipf's law implementation
    raise NotImplementedError("Zipf generation is not implemented yet.")

async def _get_words_corpus(lang: str, to_lang: str, words_so_far: list, level: str, model: str, max_words: int) -> list:
    """Generate a list of words using a corpus."""
    # Placeholder for corpus-based implementation
    raise NotImplementedError("Corpus generation is not implemented yet.")



async def generate_words(lang: str, to_lang: str, words_so_far: list, level: str, method: str, provider: str, model: str, max_words: int) -> list:
    """Generate a list of words for a given language and level using the specified method and provider.
        method: ai, zipf, corpus
        provider: openai, ollama
        model: model name or identifier
        max_words: maximum number of words to generate
    """
    print(f"Generating words with method={method}, provider={provider}, model={model}, max_words={max_words}")
    if method == "ai":
        if provider == "ollama":
            return await _get_words_ollama(lang, to_lang, words_so_far, level, model, max_words)
        elif provider == "openai":
            return await _get_words_openai(lang, to_lang, words_so_far, level, model, max_words)
        else:
            raise ValueError(f"Unsupported provider: {provider}")
    elif method == "zipf":
        return await _get_words_zipf(lang, to_lang, words_so_far, level, model, max_words)
    elif method == "corpus":
        return await _get_words_corpus(lang, to_lang, words_so_far, level, model, max_words)
    else:
        raise ValueError(f"Unsupported method: {method}")


async def generate_sentences(lang: str, to_lang: str, word: str, level: str, method: str, provider: str, model: str, max_words: int, num_sentences: int) -> list:
    """Generate a list of sentences for a given language and level using the specified method and provider.
        method: ai, corpus
        provider: openai, ollama
        model: model name or identifier
        max_words: maximum number of words per sentence
        num_sentences: number of sentences to generate
    """
    if method == "ai":
        if provider == "ollama":
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
        elif provider == "corpus":
            # Placeholder for OpenAI implementation
            raise NotImplementedError("OpenAI generation is not implemented yet.")
        else:
            raise ValueError(f"Unsupported provider: {provider}")



async def generate_translated_sentences(lang: str, to_lang: str, word: str, level: str, method: str, provider: str, model: str, max_words: int, num_sentences: int) -> list:
    """Generate a list of sentences for a given language and level using the specified method and provider.
        method: ai, corpus
        provider: openai, ollama
        model: model name or identifier
        max_words: maximum number of words per sentence
        num_sentences: number of sentences to generate
    """
    if method == "ai":
        if provider == "ollama":
            prompt = (
                f"""
                Create {num_sentences} sentences in {get_language_name(lang)} that are appropriate for a {level} learner with the word '{word}' and translate them into {get_language_name(to_lang)}.
                The sentences should be translated into {get_language_name(to_lang)} 
                The maximum number of words per sentence should be {max_words}.
                Respond with ONLY a JSON array, no prose, no markdown fences, in this exact shape:
                [{"{lang}": "sentence1", "{to_lang}": "translation1"}, {"{lang}": "sentence2", "{to_lang}": "translation2"}]
                """
            )
            print(f"Prompt for Ollama: {prompt}")
            response = await get_ollama_response(prompt=prompt, model=model)
            return json.loads(response)
        elif provider == "corpus":
            # Placeholder for OpenAI implementation
            raise NotImplementedError("OpenAI generation is not implemented yet.")
        else:
            raise ValueError(f"Unsupported provider: {provider}")

async def generate_translated_sentence_distractors(lang: str, to_lang: str, word: str, level: str, method: str, provider: str, model: str, max_words: int, num_sentences: int) -> list:
    """Generate a list of sentences for a given language and level using the specified method and provider.
        method: ai, corpus
        provider: openai, ollama
        model: model name or identifier
        max_words: maximum number of words per sentence
        num_sentences: number of sentences to generate
    """
    

    if method == "ai":
        if provider == "ollama":
            prompt = (
                f"""
                Create {num_sentences} sentences in {get_language_name(lang)} that are appropriate for a {level} learner with the word '{word}' and translate them into {get_language_name(to_lang)}.
                The sentences should be translated into {get_language_name(to_lang)} 
                The maximum number of words per sentence should be {max_words}.
                Also add incorrect translations - to be used as wrong answers in a quiz.
                The incorrect translations should be a mix of:
                - somewhat similar to the correct translations.
                - completely different from the correct translations.
                Respond with ONLY a JSON array, no prose, no markdown fences, in this exact shape:
                [{"{lang}": "sentence1", "{to_lang}": "translation1", "distractors":["sentence1", "sentence2","sentence3"]},]
                """
            )
            print(f"Prompt for Ollama: {prompt}")
            response = await get_ollama_response(prompt=prompt, model=model)
            return json.loads(response)
        elif provider == "corpus":
            # Placeholder for OpenAI implementation
            raise NotImplementedError("OpenAI generation is not implemented yet.")
        else:
            raise ValueError(f"Unsupported provider: {provider}")



async def generate_translations(lang: str, to_lang: str, word: str, level: str, method: str, provider: str, model: str, max_words: int) -> list:
    """Generate a list of translations for a given language and level using the specified method and provider.
        method: ai, corpus
        provider: openai, ollama
        model: model name or identifier
        max_words: maximum number of words per translation
    """
    if method == "ai":
        if provider == "ollama":
            prompt = (
                f"""
                Translate the word '{word}' from {get_language_name(lang)} to {get_language_name(to_lang)}.
                Respond with ONLY a JSON array, no prose, no markdown fences, in this exact shape:
                ["translation1","translation2"]
                """
            )
            print(f"Prompt for Ollama: {prompt}")
            response = await get_ollama_response(prompt=prompt, model=model)
            return json.loads(response)
        elif provider == "corpus":
            # Placeholder for OpenAI implementation
            raise NotImplementedError("OpenAI generation is not implemented yet.")
        else:
            raise ValueError(f"Unsupported provider: {provider}")




def generate_exercises(sentences_translated:list, lang:str, to_lang:str) -> list[dict]:
    """ TODO: find an implementation for this function
    """
    return [{}]
