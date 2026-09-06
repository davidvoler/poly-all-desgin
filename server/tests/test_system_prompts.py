from manual_test import init_manual_tests
init_manual_tests()
import asyncio

from utils.generate_ai import (
    generate_ai_translated_sentence_distractors,
)



async def get_res():
    res = await generate_ai_translated_sentence_distractors(
    lang="it",
    to_lang="en",
    word="casa",
    level="beginner",
    provider="ollama",
    model="gemma4",
    max_words=10,
    num_sentences=3
    )
    print(res)

asyncio.run(get_res())

    