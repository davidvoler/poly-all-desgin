from manual_test import init_manual_tests
init_manual_tests()

import argparse
import asyncio
import json
import socket
import sys
import time
import random 



import utils.ollama_simple as ollama_simple
from utils.generate import (
    generate_words,
    generate_sentences,
    generate_translated_sentence_distractors,
)




def _add_common_args(p: argparse.ArgumentParser) -> None:
    p.add_argument("--lang", default="ar")
    p.add_argument("--to-lang", default="en")
    p.add_argument("--level", default="a1")
    p.add_argument("--method", default="corpus", choices=["ai", "zipf", "corpus"])
    p.add_argument("--provider", default="ollama", choices=["ollama", "openai", "corpus"])
    p.add_argument("--model", default="gemma4")
    p.add_argument("--max-words", type=int, default=20)


async def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    _add_common_args(parser)
    args = parser.parse_args()
    words = await generate_words(lang=args.lang, to_lang=args.to_lang, words_so_far=[], level=args.level, method=args.method, provider=args.provider, model=args.model, max_words=args.max_words)
    print(f"Generated words: lang : {args.lang}, words: {words}")
    for w in words:
        print(w)
        sentences = await generate_translated_sentence_distractors(lang=args.lang, to_lang=args.to_lang, word=w, level=args.level, method=args.method, provider=args.provider, model=args.model, max_words=args.max_words, num_sentences=3)
        # print(f"Generated sentences for word '{w}': {sentences}")
        for s in sentences:
            print(s)
if __name__ == "__main__":
    asyncio.run(main())
