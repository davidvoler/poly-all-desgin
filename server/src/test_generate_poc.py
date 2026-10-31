"""CLI for exercising utils/generate_poc.py's functions directly against
a real Ollama instance, without going through the FastAPI router or a
database. Run from server/src (matches test_course_export.py's convention):

    python test_generate_poc.py words --lang en --to-lang es --level beginner --max-words 8
    python test_generate_poc.py sentences --lang en --word dog --num-sentences 3
    python test_generate_poc.py translated-sentences --lang en --to-lang es --word dog
    python test_generate_poc.py distractors --lang en --to-lang es --word dog
    python test_generate_poc.py translations --lang en --to-lang es --word dog
    python test_generate_poc.py exercises --lang en --to-lang es

ollama_simple.get_ollama_response() hardcodes host.docker.internal (the
address the *server container* uses to reach Ollama on the host). This
script auto-swaps that for localhost when host.docker.internal doesn't
resolve, so `python test_generate_poc.py ...` also works run directly
on the host, outside Docker. Override with --ollama-host if neither
guess is right.
"""
import argparse
import asyncio
import json
import socket
import sys
import time

import utils.ollama_simple as ollama_simple
from utils.generate import (
    generate_words,
    generate_sentences,
    generate_translated_sentences,
    generate_translated_sentence_distractors,
    generate_translations,
    generate_exercises,
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
    p.add_argument("--lang", default="en")
    p.add_argument("--to-lang", default="es")
    p.add_argument("--level", default="beginner")
    p.add_argument("--method", default="ai", choices=["ai", "zipf", "corpus"])
    p.add_argument("--provider", default="ollama", choices=["ollama", "openai", "corpus"])
    p.add_argument("--model", default="gemma4")
    p.add_argument("--max-words", type=int, default=10)
    if word:
        p.add_argument("--word", default="dog")
    if num_sentences:
        p.add_argument("--num-sentences", type=int, default=3)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--ollama-host", default=None, help="e.g. http://localhost:11434 (default: auto-detect)")
    sub = parser.add_subparsers(dest="command", required=True)

    p_words = sub.add_parser("words", help="generate_words()")
    _add_common_args(p_words)
    p_words.add_argument("--words-so-far", default="", help="comma-separated list")

    p_sentences = sub.add_parser("sentences", help="generate_sentences()")
    _add_common_args(p_sentences, num_sentences=True, word=True)

    p_translated = sub.add_parser("translated-sentences", help="generate_translated_sentences()")
    _add_common_args(p_translated, num_sentences=True, word=True)

    p_distractors = sub.add_parser("distractors", help="generate_translated_sentence_distractors()")
    _add_common_args(p_distractors, num_sentences=True, word=True)

    p_translations = sub.add_parser("translations", help="generate_translations()")
    _add_common_args(p_translations, word=True)

    p_exercises = sub.add_parser("exercises", help="generate_exercises() (sync, no AI call)")
    p_exercises.add_argument("--lang", default="en")
    p_exercises.add_argument("--to-lang", default="es")
    p_exercises.add_argument("--sentences-json", default="[]", help="JSON list passed as sentences_translated")

    args = parser.parse_args()

    if args.command != "exercises":
        _patch_ollama_host(args.ollama_host)

    if args.command == "words":
        words_so_far = [w.strip() for w in args.words_so_far.split(",") if w.strip()]
        coro = generate_words(args.lang, args.to_lang, words_so_far, args.level, args.method, args.provider, args.model, args.max_words)
        asyncio.run(_run("generate_words", coro))
    elif args.command == "sentences":
        coro = generate_sentences(args.lang, args.to_lang, args.word, args.level, args.method, args.provider, args.model, args.max_words, args.num_sentences)
        asyncio.run(_run("generate_sentences", coro))
    elif args.command == "translated-sentences":
        coro = generate_translated_sentences(args.lang, args.to_lang, args.word, args.level, args.method, args.provider, args.model, args.max_words, args.num_sentences)
        asyncio.run(_run("generate_translated_sentences", coro))
    elif args.command == "distractors":
        coro = generate_translated_sentence_distractors(args.lang, args.to_lang, args.word, args.level, args.method, args.provider, args.model, args.max_words, args.num_sentences)
        asyncio.run(_run("generate_translated_sentence_distractors", coro))
    elif args.command == "translations":
        coro = generate_translations(args.lang, args.to_lang, args.word, args.level, args.method, args.provider, args.model, args.max_words)
        asyncio.run(_run("generate_translations", coro))
    elif args.command == "exercises":
        sentences_translated = json.loads(args.sentences_json)
        result = generate_exercises(sentences_translated, args.lang, args.to_lang)
        asyncio.run(_run("generate_exercises", result))


if __name__ == "__main__":
    main()
