"""Integration tests for utils/generate.py — the content-generation entry
points the AI-course flow calls.

`generate_words` / `generate_sentences` /
`generate_translated_sentence_distractors` each fan out to a `corpus`
branch (SQL against the content DB) or an `ai` branch (an Ollama model).
Both are exercised for real here:

  * `corpus` tests -> @pytest.mark.db      (need postgres_content)
  * `ai` tests     -> @pytest.mark.ollama  (need a running model; slow)

The `ai` distractor tests double as a regression guard for the reworked
prompt in utils/generate_ai.py: every field must come back in the right
language/script.
"""
import unicodedata

import pytest

from utils.generate import (
    generate_sentences,
    generate_translated_sentence_distractors,
    generate_words,
)

# --- helpers --------------------------------------------------------------

SCRIPT_BY_LANG = {"ar": "arabic", "he": "hebrew", "en": "latin", "es": "latin", "ja": "cjk"}


def script_of(text: str) -> str:
    """Coarse writing-system of the first alphabetic char — enough to tell
    Arabic / Hebrew / Latin / CJK apart, which is what the prompt fix is
    about."""
    for ch in text:
        if not ch.isalpha():
            continue
        name = unicodedata.name(ch, "")
        if name.startswith("HEBREW"):
            return "hebrew"
        if name.startswith("ARABIC"):
            return "arabic"
        if name.startswith(("CJK", "HIRAGANA", "KATAKANA")):
            return "cjk"
        if "LATIN" in name:
            return "latin"
        return "other"
    return "empty"


# ---------------------------------------------------------------------------
# generate_words — corpus branch (real SQL)
# ---------------------------------------------------------------------------
@pytest.mark.db
class TestGenerateWordsCorpus:
    async def test_returns_words_in_the_requested_language(self):
        words = await generate_words(
            lang="ar", to_lang="en", words_so_far=[], level="a1",
            content_source="corpus", provider="corpus", model="", max_words=10,
        )
        assert isinstance(words, list)
        assert 1 <= len(words) <= 10
        assert all(isinstance(w, str) and w for w in words)
        assert all(script_of(w) == "arabic" for w in words)

    async def test_honours_max_words(self):
        words = await generate_words(
            lang="ar", to_lang="en", words_so_far=[], level="a1",
            content_source="corpus", provider="corpus", model="", max_words=3,
        )
        assert len(words) <= 3

    async def test_excludes_words_so_far(self):
        first = await generate_words(
            lang="ar", to_lang="en", words_so_far=[], level="a1",
            content_source="corpus", provider="corpus", model="", max_words=5,
        )
        assert first, "expected some corpus words to build on"
        again = await generate_words(
            lang="ar", to_lang="en", words_so_far=first, level="a1",
            content_source="corpus", provider="corpus", model="", max_words=5,
        )
        assert set(again).isdisjoint(first)

    async def test_english_corpus(self):
        words = await generate_words(
            lang="en", to_lang="ar", words_so_far=[], level="a2",
            content_source="corpus", provider="corpus", model="", max_words=8,
        )
        assert words
        assert all(script_of(w) in ("latin", "other") for w in words)

    async def test_missing_language_yields_nothing(self):
        # 'he' isn't loaded in content_raw.words — corpus should just be empty,
        # not raise.
        words = await generate_words(
            lang="he", to_lang="en", words_so_far=[], level="a1",
            content_source="corpus", provider="corpus", model="", max_words=10,
        )
        assert words == []


# ---------------------------------------------------------------------------
# generate_words — ai branch (real model)
# ---------------------------------------------------------------------------
@pytest.mark.ollama
class TestGenerateWordsAI:
    @pytest.mark.parametrize("lang", ["ar", "he"])
    async def test_returns_words_mostly_in_language(self, lang, ai_model):
        words = await generate_words(
            lang=lang, to_lang="en", words_so_far=[], level="a1",
            content_source="ai", provider="ollama", model=ai_model, max_words=6,
        )
        assert isinstance(words, list)
        assert 3 <= len(words) <= 15
        assert all(isinstance(w, str) and w.strip() for w in words)
        in_script = sum(script_of(w) == SCRIPT_BY_LANG[lang] for w in words)
        # allow the model one slip
        assert in_script >= len(words) - 1


# ---------------------------------------------------------------------------
# generate_translated_sentence_distractors — ai branch
# regression guard for the reworked prompt (utils/generate_ai.py)
# ---------------------------------------------------------------------------
@pytest.mark.ollama
class TestDistractorsAI:
    WORD = {"ar": "بيت", "he": "בית", "en": "house"}

    @pytest.mark.parametrize(
        "lang,to_lang",
        [("ar", "en"), ("en", "he"), ("ar", "he"), ("he", "ar")],
    )
    async def test_every_field_is_in_the_expected_language(self, lang, to_lang, ai_model):
        items = await generate_translated_sentence_distractors(
            lang=lang, to_lang=to_lang, word=self.WORD[lang], level="a2",
            content_source="ai", provider="ollama", model=ai_model,
            max_words=8, num_sentences=2,
        )
        assert isinstance(items, list) and items

        for it in items:
            assert {"sentence", "translation", "distractors"} <= set(it), it
            assert len(it["distractors"]) >= 3

            assert script_of(it["sentence"]) == SCRIPT_BY_LANG[lang], it["sentence"]
            assert script_of(it["translation"]) == SCRIPT_BY_LANG[to_lang], it["translation"]
            for d in it["distractors"]:
                assert script_of(d) == SCRIPT_BY_LANG[to_lang], (to_lang, d)

            # "wrong options" — none should equal the correct translation
            assert it["translation"] not in it["distractors"]


# ---------------------------------------------------------------------------
# generate_sentences — corpus branch
# ---------------------------------------------------------------------------
@pytest.mark.db
class TestGenerateSentencesCorpus:
    async def test_returns_source_language_rows(self):
        rows = await generate_sentences(
            lang="ar", to_lang="en", word="أنا", level="a1",
            content_source="corpus", provider="corpus", model="",
            max_words=12, num_sentences=3,
        )
        assert isinstance(rows, list) and rows
        for r in rows:
            assert r.get("sentences"), r
            assert script_of(r["sentences"]) == "arabic"


# ---------------------------------------------------------------------------
# routing
# ---------------------------------------------------------------------------
async def test_unknown_content_source_raises():
    with pytest.raises(ValueError):
        await generate_words(
            lang="ar", to_lang="en", words_so_far=[], level="a1",
            content_source="bogus", provider="ollama", model="x", max_words=3,
        )
