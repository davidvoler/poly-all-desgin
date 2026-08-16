import json
import re

# from utils.ollama_client import ollama_chat, OllamaError
from utils.ollama_simple import get_ollama_response


def _extract_json_array(text: str) -> list:
    """Ollama models tend to wrap JSON in prose or ```json fences even
    when asked not to — pull out the first [...] array and parse that."""
    match = re.search(r"\[.*\]", text, re.DOTALL)
    if not match:
        raise RuntimeError(f"No JSON array found in Ollama response: {text!r}")
    return json.loads(match.group(0))


async def _get_words_ollama(lang: str, to_lang: str, words_so_far: list, level: str, model: str, max_words: int) -> list:
    """Generate a list of words using Ollama."""
    prompt = (
        f"""
           Create a list of 12 words in Japanese that are appropriate for a A1 learner
           Respond with ONLY a JSON array, no prose, no markdown fences, in this exact shape:
           ["word1","word2"]
        """
    )
    print(f"Prompt for Ollama: {prompt}")
    response = await get_ollama_response(prompt=prompt, model=model)
    # print(f"Ollama response: {response}", type(response))
    # print(response)
    # print(type(response))
    return json.loads(response)
    # return ['a', 'b', 'c']  # Placeholder for testing
    # return json.loads(response)  # Assuming the response is a JSON array string
    
    # try:
    #     response = await ollama_chat(prompt=prompt, model=model)
    # except OllamaError as e:
    #     raise RuntimeError(f"Ollama generation failed: {e}") from e
    # return _extract_json_array(response.get("text", ""))


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
