"""Shared setup for the server test suite.

These are integration tests: they run against the real services, not
mocks —

  * the content Postgres  (utils.db_content -> the `postgres_content` DB)
  * a real Ollama model   (utils.ollama_simple / utils.generate_ai)

so they need those up. The easy way is from inside the server container,
where both are already reachable:

    docker compose exec -w /app/tests server python -m pytest -q

Select a subset with the markers:

    ... python -m pytest -q -m db            # only DB-backed
    ... python -m pytest -q -m "not ollama"  # skip the slow model calls
"""
import os
import socket
import sys
from pathlib import Path

# --- make the app importable ------------------------------------------------
# In the container the source is mounted at /app and this suite at
# /app/tests; on a plain host checkout the code is under server/src.
_here = Path(__file__).resolve().parent
for _cand in (_here.parent, _here.parent / "src"):
    if (_cand / "utils").is_dir():
        sys.path.insert(0, str(_cand))
        break

# --- service endpoints -----------------------------------------------------
# Postgres: inside the container the compose env already points at the
# service names, so only fill what a host run would be missing.
os.environ.setdefault("POSTGRES_CONTENT_HOST", "localhost")
os.environ.setdefault("POSTGRES_CONTENT_PORT", "5433")


def _resolves(host: str) -> bool:
    try:
        socket.gethostbyname(host)
        return True
    except OSError:
        return False


# Ollama runs on the host. utils.ollama_simple reads OLLAMA_HOST at import
# time, so this must be set before any test imports utils.generate. In the
# container `host.docker.internal` reaches the host; on a host run it's
# localhost.
if "OLLAMA_HOST" not in os.environ:
    _host = "host.docker.internal" if _resolves("host.docker.internal") else "localhost"
    os.environ["OLLAMA_HOST"] = f"http://{_host}:11434"

import pytest

# Legacy hand-run scripts in this folder execute on import (asyncio.run at
# module scope) — keep pytest from collecting them.
collect_ignore = ["test_system_prompts.py", "test_generate_full_process.py"]


@pytest.fixture(scope="session")
def ai_model() -> str:
    """Ollama model the AI-path tests use. Override with $TEST_OLLAMA_MODEL."""
    return os.environ.get("TEST_OLLAMA_MODEL", "muse-glimmer")


@pytest.fixture(scope="session", autouse=True)
async def _close_content_db():
    """utils.db_content keeps one connection on a module global; close it
    when the session ends so pytest doesn't warn about a live socket."""
    yield
    try:
        from utils.db_content import close_pg_con

        await close_pg_con()
    except Exception:
        pass
