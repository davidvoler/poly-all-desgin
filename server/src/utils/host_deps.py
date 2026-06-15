"""FastAPI dependencies for reading the request's hostname — the
companion to utils/auth_deps.py's `current_user_id`. The hostname is
how we identify the school tenant in prod, where each school is served
from its own subdomain (e.g. `school1.app.polyglots.social`).

Source precedence:
  1. `X-Forwarded-Host` — the original Host once we're behind the prod
     reverse proxy, which rewrites `Host` to the upstream.
  2. `request.url.hostname` — the URL Starlette parsed from the request
     line / `Host` header. Correct for direct (dev) connections.
"""
from fastapi import Request


def current_host(request: Request) -> str:
    """Bare hostname for the request, lowercased and port-stripped.

    e.g. `school1.app.polyglots.social`, `localhost`. Empty string if
    the host can't be determined (shouldn't happen for HTTP requests)."""
    forwarded = request.headers.get("x-forwarded-host")
    if forwarded:
        # May be a comma-separated chain (proxy1, proxy2); the first
        # entry is the original client-facing host.
        host = forwarded.split(",")[0].strip()
    else:
        host = request.url.hostname or ""
    # Drop any `:port` and normalise case for downstream comparisons.
    return host.split(":")[0].strip().lower()
