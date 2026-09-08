from manual_test import init_manual_tests
init_manual_tests()
import asyncio

from utils.generate_ai import (
    generate_ai_words,
    generate_ai_translated_sentence_distractors,
)



async def get_res():
    res = await generate_ai_translated_sentence_distractors(
    lang="ar",
    to_lang="he",
    word="رأيتُ",
    level="beginner",
    provider="ollama",
    model="muse-glimmer",
    max_words=10,
    num_sentences=3
    )
    print(res)


async def gen_words():
    words = await generate_ai_words(
        lang="ar",
        to_lang="he",
        words_so_far=[],
        level="C1",
        provider="ollama",
        model="gemma4",
        max_words=300
    )
    print(words)


asyncio.run(get_res())
# asyncio.run(gen_words())

    