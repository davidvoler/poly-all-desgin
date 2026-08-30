from utils.generate_ai import(
    generate_ai_words,
    generate_ai_sentences,
    generate_ai_translated_sentence_distractors,
)
from utils.generate_corpus import(
    get_corpus_words,
    get_corpus_sentences,
    get_corpus_sentences_distractors,
)

async def generate_words(lang: str, to_lang: str, words_so_far: list, level: str, content_source: str, provider: str, model: str, max_words: int) -> list:
    """Generate a list of words for a given language and level using the specified content_source and provider.
        content_source: ai, corpus
        provider: openai, ollama
        model: model name or identifier
        max_words: maximum number of words to generate
    """
    print(f"Generating words with content_source={content_source}, provider={provider}, model={model}, max_words={max_words}")
    if content_source == "ai":
        return await generate_ai_words(lang, to_lang, words_so_far, level, provider, model, max_words)
    elif content_source == "corpus":
        return await get_corpus_words(lang, to_lang, words_so_far, level, model, max_words)
    else:
        raise ValueError(f"Unsupported content_source: {content_source}")

async def generate_sentences(lang: str, to_lang: str, word: str, level: str, content_source: str, provider: str, model: str, max_words: int, num_sentences: int) -> list:
    """Generate a list of sentences for a given language and level using the specified content_source and provider.
        content_source: ai, corpus
        provider: openai, ollama
        model: model name or identifier
        max_words: maximum number of words per sentence
        num_sentences: number of sentences to generate
    """
    if content_source == "ai":
        return await generate_ai_sentences(lang, to_lang, word, level, provider, model, max_words, num_sentences)
    elif content_source == "corpus":
        return await get_corpus_sentences(lang, to_lang, word, level, model, max_words, num_sentences)
    else:
        raise ValueError(f"Unsupported content_source: {content_source}")

async def generate_translated_sentence_distractors(lang: str, 
                                                   to_lang: str, 
                                                   word: str, 
                                                   level: str, 
                                                   content_source: str, 
                                                   provider: str, 
                                                   model: str, 
                                                   max_words: int, 
                                                   num_sentences: int) -> list:
    """Generate a list of sentences for a given language and level using the specified content_source and provider.
        content_source: ai, corpus
        provider: openai, ollama
        model: model name or identifier
        max_words: maximum number of words per sentence
        num_sentences: number of sentences to generate
    """
    if content_source == "ai":
        return await generate_ai_translated_sentence_distractors(lang, to_lang, word, level, provider, model, max_words, num_sentences)
    elif content_source == "corpus":
        return await get_corpus_sentences_distractors(lang, to_lang, word, level, model, max_words, num_sentences)
    else:
        raise ValueError(f"Unsupported content_source: {content_source}")


