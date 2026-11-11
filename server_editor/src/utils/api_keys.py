"""AI provider API keys, stored encrypted per school or per user.

A user's own key is used before the school's. Keys are decrypted only in the
task worker, when a prompt runs (see tasks/prompt_tasks.py).
"""
import logging
import os

from models.api_key import ApiKeyInfo, ApiKeyScope
from utils import secret_box
from utils.db import get_query_results

log = logging.getLogger(__name__)

# The providers that need a key, with the server-wide environment variables
# used when a school or user has none (see env_fallback_enabled).
KEY_PROVIDERS: dict[str, tuple[str, ...]] = {
    "gemini": ("GOOGLE_API_KEY", "GEMINI_API_KEY"),
    "claude": ("ANTHROPIC_API_KEY",),
    "openai": ("OPENAI_API_KEY",),
}


def env_fallback_enabled() -> bool:
    """Whether the server's own keys are used for schools and users without one.
    On by default for local development; set AI_KEYS_ENV_FALLBACK=false in SaaS."""
    return os.getenv("AI_KEYS_ENV_FALLBACK", "true").lower() in ("1", "true", "yes")


def env_key(provider: str) -> str | None:
    if not env_fallback_enabled():
        return None
    return next((os.getenv(n) for n in KEY_PROVIDERS.get(provider, ()) if os.getenv(n)), None)


def _context(school: str, user_id: int | None, provider: str) -> str:
    return f"ai_api_key:{school}:{user_id or ''}:{provider}"


def _owner_user_id(scope: ApiKeyScope, user_id: int) -> int | None:
    return user_id if scope == ApiKeyScope.USER else None


def _last4(api_key: str) -> str:
    return api_key[-4:]


async def list_keys(school: str, user_id: int) -> list[ApiKeyInfo]:
    """The school's keys and the user's own, without the keys themselves."""
    rows = await get_query_results(
        """
        SELECT provider, user_id, last4, updated_at FROM secrets.ai_api_key
        WHERE school = %(school)s AND (user_id IS NULL OR user_id = %(user_id)s)
        ORDER BY provider, user_id NULLS FIRST
        """,
        {"school": school, "user_id": user_id},
    )
    return [
        ApiKeyInfo(
            provider=r["provider"],
            scope=ApiKeyScope.SCHOOL if r["user_id"] is None else ApiKeyScope.USER,
            last4=r["last4"],
            updated_at=r["updated_at"],
        )
        for r in rows
    ]


async def save_key(school: str, user_id: int, scope: ApiKeyScope, provider: str,
                   api_key: str) -> ApiKeyInfo:
    """Adds or replaces the school's or the user's key for [provider]."""
    if provider not in KEY_PROVIDERS:
        raise ValueError(f"Unknown provider: {provider}")
    api_key = api_key.strip()
    owner = _owner_user_id(scope, user_id)
    ciphertext, version = secret_box.encrypt(api_key, _context(school, owner, provider))
    rows = await get_query_results(
        """
        INSERT INTO secrets.ai_api_key (school, user_id, provider, ciphertext, key_version, last4)
        VALUES (%(school)s, %(user_id)s, %(provider)s, %(ciphertext)s, %(version)s, %(last4)s)
        ON CONFLICT ON CONSTRAINT ai_api_key_owner_provider DO UPDATE
        SET ciphertext = EXCLUDED.ciphertext, key_version = EXCLUDED.key_version,
            last4 = EXCLUDED.last4, updated_at = now()
        RETURNING provider, user_id, last4, updated_at
        """,
        {"school": school, "user_id": owner, "provider": provider,
         "ciphertext": ciphertext, "version": version, "last4": _last4(api_key)},
    )
    if not rows:
        raise RuntimeError("The key was not saved")
    return ApiKeyInfo(provider=provider, scope=scope, last4=rows[0]["last4"],
                      updated_at=rows[0]["updated_at"])


async def delete_key(school: str, user_id: int, scope: ApiKeyScope, provider: str) -> bool:
    rows = await get_query_results(
        """
        DELETE FROM secrets.ai_api_key
        WHERE school = %(school)s AND user_id IS NOT DISTINCT FROM %(user_id)s
          AND provider = %(provider)s
        RETURNING api_key_id
        """,
        {"school": school, "user_id": _owner_user_id(scope, user_id), "provider": provider},
    )
    return bool(rows)


async def resolve_keys(school: str | None, user_id: int | None) -> dict[str, str]:
    """The key to use for each provider: the user's, else the school's, else the
    server's own when the fallback is on. Providers without one are left out."""
    keys: dict[str, str] = {}
    if school:
        rows = await get_query_results(
            """
            SELECT provider, user_id, ciphertext, key_version FROM secrets.ai_api_key
            WHERE school = %(school)s AND (user_id IS NULL OR user_id = %(user_id)s)
            ORDER BY user_id NULLS FIRST  -- the user's key, read last, wins
            """,
            {"school": school, "user_id": user_id},
        )
        for r in rows:
            try:
                keys[r["provider"]] = secret_box.decrypt(
                    bytes(r["ciphertext"]), r["key_version"],
                    _context(school, r["user_id"], r["provider"]))
            except secret_box.SecretBoxError as e:
                scope = "school" if r["user_id"] is None else "user"
                log.error("Cannot use the %s %s key for school %s: %s",
                          scope, r["provider"], school, e)
    for provider in KEY_PROVIDERS:
        if provider not in keys and (key := env_key(provider)):
            keys[provider] = key
    return keys


async def key_sources(school: str, user_id: int) -> dict[str, str]:
    """Where each provider's key comes from (user, school or server), without
    decrypting anything. Providers without a key are left out."""
    sources = {}
    for info in await list_keys(school, user_id):
        if sources.get(info.provider) != ApiKeyScope.USER.value:
            sources[info.provider] = info.scope.value
    for provider in KEY_PROVIDERS:
        if provider not in sources and env_key(provider):
            sources[provider] = "server"
    return sources
