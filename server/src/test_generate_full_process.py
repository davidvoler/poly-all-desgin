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


def _resolves(host: str) -> bool:
    try:
        socket.gethostbyname(host)
        return True
    except socket.gaierror:
        return False


def _patch_ollama_host(host: str | None) -> None:
    if host is None:
        host = "http://host.docker.internal:11434" if _resolves("host.docker.internal") else "http://localhost:11434"
    real_async_client = ollama_simple.AsyncClient
    ollama_simple.AsyncClient = lambda *a, **kw: real_async_client(host=host)
    print(f"[ollama host: {host}]\n")


def _print_result(result) -> None:
    print(json.dumps(result, indent=2, ensure_ascii=False))


async def _run(label: str, coro) -> None:
    start = time.monotonic()
    try:
        result = coro if not asyncio.iscoroutine(coro) else await coro
    except Exception as e:
        elapsed = time.monotonic() - start
        print(f"[{label}] FAILED after {elapsed:.2f}s: {type(e).__name__}: {e}", file=sys.stderr)
        raise SystemExit(1)
    elapsed = time.monotonic() - start
    print(f"[{label}] OK in {elapsed:.2f}s\n")
    _print_result(result)


def _add_common_args(p: argparse.ArgumentParser, *, num_sentences=False, word=False) -> None:
    p.add_argument("--lang", default="it")
    p.add_argument("--to-lang", default="en")
    p.add_argument("--level", default="beginner")
    p.add_argument("--method", default="ai", choices=["ai", "zipf", "corpus"])
    p.add_argument("--provider", default="ollama", choices=["ollama", "openai", "corpus"])
    p.add_argument("--model", default="muse-glimmer")
    p.add_argument("--max-words", type=int, default=10)
    if word:
        p.add_argument("--word", default="dog")
    if num_sentences:
        p.add_argument("--num-sentences", type=int, default=3)


async def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)

    _add_common_args(parser, num_sentences=True, word=True)
    parser.add_argument("--ollama-host", default='http://localhost:11434', help="e.g. http://localhost:11434 (default: auto-detect)")
    print("Starting test_generate_poc.py")
    args = parser.parse_args()
    _patch_ollama_host(args.ollama_host)
    
    words = await generate_words(lang=args.lang, to_lang=args.to_lang, words_so_far=[], level=args.level, method=args.method, provider=args.provider, model=args.model, max_words=args.max_words)
    # print(f"Generated words: {words}")
    words_for_exercise = random.sample(words, min(len(words), 3))
    print(f"Words for exercise: {words_for_exercise}")
    for w in words_for_exercise:
        sentences = await generate_translated_sentence_distractors(lang=args.lang, to_lang=args.to_lang, word=w, level=args.level, method=args.method, provider=args.provider, model=args.model, max_words=args.max_words, num_sentences=args.num_sentences)
        print(f"Generated sentences for word '{w}': {sentences}")


if __name__ == "__main__":
    asyncio.run(main())
