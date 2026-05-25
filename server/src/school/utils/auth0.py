"""Auth0 ID-token verification for the dashboard's `/login_auth0` route.

The dashboard hands us an Auth0-issued ID token; we verify it against
the tenant's JWKS, then trust the `email` claim to look up an existing
school_users row. The route owns the user-lookup decision — this
module only deals with cryptographic verification.

Env vars (read on first verify, cached for the process lifetime):
  AUTH0_DOMAIN     — e.g. `polyglots.us.auth0.com`. Required.
  AUTH0_AUDIENCE   — the API audience the dashboard requested. Optional;
                     when set we enforce it. When empty we skip the
                     `aud` check (useful while wiring up).
  AUTH0_CLIENT_ID  — Optional fallback audience: ID tokens have
                     `aud == client_id` by default, so when
                     AUTH0_AUDIENCE is empty we accept this instead.

Everything is opt-in: if AUTH0_DOMAIN isn't set, [is_enabled] returns
False and the route returns a clean 503 instead of trying to verify.
"""
from __future__ import annotations

import os
import time
from typing import Any

import httpx
from jose import jwt
from jose.exceptions import JWTError


_JWKS_CACHE: dict[str, Any] = {}
_JWKS_TTL_SECONDS = 60 * 60  # 1 hour — JWKS rotation is rare


def is_enabled() -> bool:
    """True when the server has enough config to verify Auth0 tokens.
    The /login_auth0 route returns 503 when this is false so the
    dashboard can fall back to the local password flow cleanly."""
    return bool(os.getenv("AUTH0_DOMAIN", "").strip())


def _domain() -> str:
    d = os.getenv("AUTH0_DOMAIN", "").strip()
    if not d:
        raise RuntimeError("AUTH0_DOMAIN is not set")
    # Tolerate either `tenant.auth0.com` or `https://tenant.auth0.com/`.
    if d.startswith("http://") or d.startswith("https://"):
        d = d.split("://", 1)[1]
    return d.rstrip("/")


def _issuer() -> str:
    return f"https://{_domain()}/"


def _audience_candidates() -> list[str]:
    """ID tokens have `aud == client_id`. Access tokens have
    `aud == api audience`. We accept either when configured so the
    dashboard can hand us whichever it has on hand."""
    out: list[str] = []
    for key in ("AUTH0_AUDIENCE", "AUTH0_CLIENT_ID"):
        v = os.getenv(key, "").strip()
        if v:
            out.append(v)
    return out


async def _fetch_jwks() -> dict:
    domain = _domain()
    now = time.time()
    cached = _JWKS_CACHE.get(domain)
    if cached and (now - cached["at"]) < _JWKS_TTL_SECONDS:
        return cached["jwks"]
    url = f"https://{domain}/.well-known/jwks.json"
    async with httpx.AsyncClient(timeout=10.0) as client:
        resp = await client.get(url)
        resp.raise_for_status()
        jwks = resp.json()
    _JWKS_CACHE[domain] = {"jwks": jwks, "at": now}
    return jwks


async def verify_id_token(token: str) -> dict:
    """Verify an Auth0 ID token and return the decoded claims dict.
    Raises ValueError on any verification failure — the route maps
    that to a 401 so we never leak which step failed."""
    if not token:
        raise ValueError("Empty token")

    try:
        unverified_header = jwt.get_unverified_header(token)
    except JWTError as e:
        raise ValueError(f"Malformed token header: {e}") from e

    kid = unverified_header.get("kid")
    if not kid:
        raise ValueError("Token header missing kid")

    jwks = await _fetch_jwks()
    key = next((k for k in jwks.get("keys", []) if k.get("kid") == kid), None)
    if key is None:
        # Maybe JWKS rotated since we cached — refetch once.
        _JWKS_CACHE.pop(_domain(), None)
        jwks = await _fetch_jwks()
        key = next(
            (k for k in jwks.get("keys", []) if k.get("kid") == kid), None)
        if key is None:
            raise ValueError("Signing key not found in JWKS")

    auds = _audience_candidates()
    decode_kwargs: dict[str, Any] = {
        "algorithms": [unverified_header.get("alg", "RS256")],
        "issuer": _issuer(),
    }
    # python-jose accepts a single string or a list for `audience` —
    # passing a list means "any of these"; missing aud check entirely
    # when we have no configured audience.
    if auds:
        decode_kwargs["audience"] = auds if len(auds) > 1 else auds[0]
    else:
        # No configured audience → skip the audience check rather than
        # rejecting every token. Useful for the first-time hookup.
        decode_kwargs["options"] = {"verify_aud": False}

    try:
        claims = jwt.decode(token, key, **decode_kwargs)
    except JWTError as e:
        raise ValueError(f"Token verification failed: {e}") from e

    return claims
