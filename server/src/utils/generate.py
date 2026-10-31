import random

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


def _resolve_content_source(content_source: str | None, method: str | None) -> str:
    source = content_source or method or "ai"
    return source


async def generate_words(
    lang: str,
    to_lang: str,
    words_so_far: list | None = None,
    level: str = "",
    content_source: str | None = None,
    provider: str = "",
    model: str = "",
    max_words: int = 10,
    method: str | None = None,
) -> list:
    """Generate a list of words for a given language and level.

    Backwards compatible with the older `method=` API and the current
    `content_source=` API.
    """
    content_source = _resolve_content_source(content_source, method)
    words_so_far = words_so_far or []
    print(f"Generating words with content_source={content_source}, provider={provider}, model={model}, max_words={max_words}")
    if content_source == "ai":
        return await generate_ai_words(lang, to_lang, words_so_far, level, provider, model, max_words)
    elif content_source == "corpus":
        return await get_corpus_words(lang, to_lang, words_so_far, level, model, max_words)
    else:
        raise ValueError(f"Unsupported content_source: {content_source}")


async def generate_sentences(
    lang: str,
    to_lang: str,
    word: str,
    level: str,
    content_source: str | None = None,
    provider: str = "",
    model: str = "",
    max_words: int = 10,
    num_sentences: int = 3,
    method: str | None = None,
) -> list:
    """Generate a list of sentences for a given language and level.

    Backwards compatible with the older `method=` API and the current
    `content_source=` API.
    """
    content_source = _resolve_content_source(content_source, method)
    if content_source == "ai":
        return await generate_ai_sentences(
            lang=lang,
            to_lang=to_lang,
            word=word,
            level=level,
            provider=provider,
            model=model,
            max_words=max_words,
            num_sentences=num_sentences,
        )
    elif content_source == "corpus":
        return await get_corpus_sentences(lang, to_lang, word, level, model, max_words, num_sentences)
    else:
        raise ValueError(f"Unsupported content_source: {content_source}")


async def generate_translated_sentence_distractors(
    lang: str,
    to_lang: str,
    word: str,
    level: str,
    content_source: str | None = None,
    provider: str = "",
    model: str = "",
    max_words: int = 10,
    num_sentences: int = 3,
    method: str | None = None,
) -> list:
    """Generate translated sentence items with target-language distractors."""
    content_source = _resolve_content_source(content_source, method)
    if content_source == "ai":
        return await generate_ai_translated_sentence_distractors(lang, to_lang, word, level, provider, model, max_words, num_sentences)
    elif content_source == "corpus":
        return await get_corpus_sentences_distractors(lang, to_lang, word, level, model, max_words, num_sentences)
    else:
        raise ValueError(f"Unsupported content_source: {content_source}")


async def generate_translated_sentences(
    lang: str,
    to_lang: str,
    word: str,
    level: str,
    content_source: str | None = None,
    provider: str = "",
    model: str = "",
    max_words: int = 10,
    num_sentences: int = 3,
    method: str | None = None,
) -> list:
    """Compatibility wrapper for the older CLI API.

    The project historically used a separate translated-sentences helper, but the
    actual sentence+distractor API already matches the downstream shape.
    """
    return await generate_translated_sentence_distractors(
        lang=lang,
        to_lang=to_lang,
        word=word,
        level=level,
        content_source=content_source,
        provider=provider,
        model=model,
        max_words=max_words,
        num_sentences=num_sentences,
        method=method,
    )


async def generate_translations(
    lang: str,
    to_lang: str,
    word: str,
    level: str,
    content_source: str | None = None,
    provider: str = "",
    model: str = "",
    max_words: int = 10,
    method: str | None = None,
) -> list[str]:
    """Return translated forms for a given word.

    For the AI path the model is asked for a short JSON list. For the corpus path,
    the existing sentence corpus is queried and the target-language translation is
    extracted from the first matching rows.
    """
    content_source = _resolve_content_source(content_source, method)
    if content_source == "corpus":
        rows = await get_corpus_sentences_distractors(lang, to_lang, word, level, model, max_words, 1)
        return [row.get(to_lang) or row.get("translation") for row in rows if row.get(to_lang) or row.get("translation")]

    prompt = (
        f"Translate the word '{word}' from {lang} to {to_lang}. "
        "Return ONLY a JSON array with the translated word as the first element, for example [\"palabra\"]."
    )
    from utils.ollama_simple import get_ollama_response

    response = await get_ollama_response(prompt=prompt, model=model)
    import json

    try:
        parsed = json.loads(response)
    except json.JSONDecodeError:
        raise
    if isinstance(parsed, list):
        return [str(item) for item in parsed if item]
    if isinstance(parsed, str):
        return [parsed]
    return []


def generate_exercises(sentences_translated: list[dict] | list, lang: str, to_lang: str) -> list[dict]:
    """Materialize sentence-only data into basic multiple-choice exercise rows.

    The legacy CLI script passes a list of dicts (`sentence`, `translation`,
    `distractors`) and expects a list of exercise-like dicts back. Keep the
    structure shallow and deterministic enough for downstream scripts and tests.
    """
    exercises: list[dict] = []
    for item in sentences_translated or []:
        if isinstance(item, dict):
            sentence = item.get("sentence") or item.get(lang) or ""
            translation = item.get("translation") or item.get(to_lang) or ""
            distractors = [d for d in (item.get("distractors") or item.get("wrong_options") or []) if d and d != translation]
        else:
            sentence = ""
            translation = str(item)
            distractors = []

        options = list(distractors)
        for candidate in (translation,):
            if candidate and candidate not in options:
                options.append(candidate)
        if not options:
            options = [translation]
        random.shuffle(options)
        exercises.append(
            {
                "sentence": sentence,
                "translation": translation,
                "distractors": distractors,
                "options": options,
                "answer": translation,
            }
        )
    return exercises


__all__ = [
    "generate_words",
    "generate_sentences",
    "generate_translated_sentence_distractors",
    "generate_translated_sentences",
    "generate_translations",
    "generate_exercises",
]


