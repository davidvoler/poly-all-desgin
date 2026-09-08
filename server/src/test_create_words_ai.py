"""Checks for the "create word list with AI" path.

The dashboard's "Generate word list" button (Words tab) POSTs to
`/api/v1/generate_poc/generate_words_list`, whose worker task calls
`utils.generate.generate_words(content_source="ai", ...)`. That routes to
`utils.generate_ai.generate_ai_words()`, which prompts the model for a
JSON array of words and `json.loads()` the reply.

The model call (`utils.ollama_simple.get_ollama_response`) is stubbed, so
this runs without an Ollama instance or a database. Run from server/src
(same convention as test_generate_poc.py / test_course_export.py):

    python test_create_words_ai.py

or inside the server container:

    docker compose exec server python test_create_words_ai.py
"""
import asyncio
import json
import sys
import time
from unittest.mock import AsyncMock, patch

from utils.generate import generate_words

_results: list[tuple[str, bool]] = []


def check(name: str, cond: object) -> None:
    ok = bool(cond)
    _results.append((name, ok))
    print(f"  [{'PASS' if ok else 'FAIL'}] {name}")


# generate_ai_words does `from utils.ollama_simple import get_ollama_response`,
# so the name to patch lives on utils.generate_ai.
_OLLAMA = "utils.generate_ai.get_ollama_response"


async def test_returns_model_word_list() -> None:
    fake = AsyncMock(return_value='["كتاب", "ولد", "بنت"]')
    with patch(_OLLAMA, fake):
        words = await generate_words(
            lang="ar", to_lang="en", words_so_far=[], level="a1",
            content_source="ai", provider="ollama", model="gemma4", max_words=3,
        )
    check("returns the list the model produced", words == ["كتاب", "ولد", "بنت"])
    check("calls the model exactly once", fake.await_count == 1)


async def test_prompt_carries_language_level_count_model() -> None:
    fake = AsyncMock(return_value="[]")
    with patch(_OLLAMA, fake):
        await generate_words(
            lang="ar", to_lang="en", words_so_far=[], level="b1",
            content_source="ai", provider="ollama", model="muse-glimmer", max_words=12,
        )
    prompt = fake.await_args.kwargs.get("prompt", "")
    check("prompt names the language in full", "Arabic" in prompt)
    check("prompt asks for the requested count", "12" in prompt)
    check("prompt includes the learner level", "b1" in prompt)
    check("selected model is forwarded to the model call",
          fake.await_args.kwargs.get("model") == "muse-glimmer")


async def test_corpus_source_does_not_hit_the_model() -> None:
    fake = AsyncMock(return_value="[]")
    corpus = AsyncMock(return_value=["bar", "baz"])
    with patch(_OLLAMA, fake), patch("utils.generate.get_corpus_words", corpus):
        words = await generate_words(
            lang="ar", to_lang="en", words_so_far=[], level="a1",
            content_source="corpus", provider="ollama", model="gemma4", max_words=2,
        )
    check("corpus source returns corpus words", words == ["bar", "baz"])
    check("corpus source never calls the model", fake.await_count == 0)


async def test_non_json_model_output_raises() -> None:
    fake = AsyncMock(return_value="Sure! Here are some words: kitab, walad")
    raised = False
    with patch(_OLLAMA, fake):
        try:
            await generate_words(
                lang="ar", to_lang="en", words_so_far=[], level="a1",
                content_source="ai", provider="ollama", model="gemma4", max_words=3,
            )
        except json.JSONDecodeError:
            raised = True
    check("non-JSON model output surfaces as JSONDecodeError", raised)


async def test_unknown_content_source_raises() -> None:
    raised = False
    try:
        await generate_words(
            lang="ar", to_lang="en", words_so_far=[], level="a1",
            content_source="nonsense", provider="ollama", model="gemma4", max_words=3,
        )
    except ValueError:
        raised = True
    check("unknown content_source raises ValueError", raised)


async def main() -> None:
    tests = [
        test_returns_model_word_list,
        test_prompt_carries_language_level_count_model,
        test_corpus_source_does_not_hit_the_model,
        test_non_json_model_output_raises,
        test_unknown_content_source_raises,
    ]
    start = time.monotonic()
    for t in tests:
        print(t.__name__)
        await t()

    passed = sum(1 for _, ok in _results if ok)
    failed = [name for name, ok in _results if not ok]
    print()
    print(f"{passed}/{len(_results)} checks passed in {time.monotonic() - start:.2f}s")
    if failed:
        print("FAILED: " + ", ".join(failed))
        sys.exit(1)
    print("OK")


if __name__ == "__main__":
    asyncio.run(main())
