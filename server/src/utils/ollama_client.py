"""Ollama provider — local LLM inference via Ollama's HTTP API. The
first real (non-mocked) model call in the create-with-AI pipeline; see
TASKS.md "Claude tasks" ("Start using ollama") and "Data model
correction". Everything else in ai_course_content.py is still a curated
mock — this is deliberately scoped to just the raw prompt path
(routers/generate_poc.py's `POST /` endpoint) rather than rewiring word/
sentence/exercise generation, which needs real prompt-engineering work
of its own.

OLLAMA_BASE_URL defaults to Docker Desktop's host-gateway alias so the
`server` container (see docker-compose.yaml) can reach an Ollama
instance running on the host — override via env when Ollama runs
somewhere else (bare-metal dev, a remote box, etc).
"""
import os
import time

import httpx

OLLAMA_BASE_URL = os.environ.get("OLLAMA_BASE_URL", "http://host.docker.internal:11434")

# Display name -> actual `ollama list` tag. Kept distinct because tags
# aren't always identical to how we want to refer to a model in the API
# (e.g. "gpt-oss-20b" is tagged "gpt-oss:20b" locally).
OLLAMA_MODELS: dict[str, str] = {
    "muse-glimmer": "muse-glimmer",
    "gemma4": "gemma4",
    "gpt-oss-20b": "gpt-oss:20b",
}
DEFAULT_MODEL = "gemma4"


class OllamaError(RuntimeError):
    pass


def resolve_model(model: str | None) -> str:
    name = model or DEFAULT_MODEL
    if name not in OLLAMA_MODELS:
        raise OllamaError(f"Unknown ollama model '{name}'. Available: {', '.join(OLLAMA_MODELS)}")
    return OLLAMA_MODELS[name]


async def ollama_chat(prompt: str, model: str | None = None, system: str | None = None) -> dict:
    """Send a single-turn prompt to a local Ollama model. Returns
    {"text", "prompt_tokens", "response_tokens", "model", "duration_ms"}.
    Local inference has no per-token billing, so there's no cost figure
    here — callers that populate PromptResponse.actual_cost should leave
    it at 0.0 for ollama-backed responses."""
    tag = resolve_model(model)
    messages = []
    if system:
        messages.append({"role": "system", "content": system})
    messages.append({"role": "user", "content": prompt})

    started = time.monotonic()
    try:
        async with httpx.AsyncClient(timeout=120.0) as client:
            resp = await client.post(
                f"{OLLAMA_BASE_URL}/api/chat",
                json={"model": tag, "messages": messages, "stream": False},
            )
            resp.raise_for_status()
    except httpx.HTTPError as e:
        raise OllamaError(f"Ollama request failed ({tag}): {e}") from e

    data = resp.json()
    if err := data.get("error"):
        raise OllamaError(f"Ollama error ({tag}): {err}")

    return {
        "text": (data.get("message") or {}).get("content", ""),
        "prompt_tokens": data.get("prompt_eval_count", 0),
        "response_tokens": data.get("eval_count", 0),
        "model": tag,
        "duration_ms": round((time.monotonic() - started) * 1000),
    }
