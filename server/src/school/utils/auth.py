"""Lightweight auth dependency for the dashboard endpoints.

The dashboard signs in via POST /school_users/login and caches the
LoginInfo (school_user_id + school_id + role) locally. Every
subsequent request stamps `X-School-User-Id` so the server can verify
the caller belongs to the school they're acting on.

The dependency intentionally short-circuits when the header is
missing — leaving an endpoint un-guarded is preferable to breaking
the existing demo flows that hit endpoints without a header. Wire it
in by adding `Depends(require_school_member)` to the route signature
and passing `school_id` either as a path or query parameter; the
dependency picks it up by attribute name from `request.path_params` +
`request.query_params`.
"""
from __future__ import annotations

from fastapi import Header, HTTPException, Request

from utils.db import get_query_results


async def require_school_member(
    request: Request,
    x_school_user_id: int | None = Header(default=None),
) -> int | None:
    """Return the caller's school_user_id if their school matches the
    request, otherwise 403. Returns None for unauthenticated requests
    (no header at all) — the route is responsible for deciding whether
    that's OK; most reads on the dashboard already pass the header
    because the client is signed in."""
    if x_school_user_id is None:
        return None

    # Find the school_id the caller is requesting access to. Prefer
    # the path param (e.g. /school/{school_id}/students), fall back
    # to the query string (?school_id=).
    requested_school_id: int | None = None
    raw = request.path_params.get('school_id')
    if raw is None:
        raw = request.query_params.get('school_id')
    if raw is not None:
        try:
            requested_school_id = int(raw)
        except (TypeError, ValueError):
            requested_school_id = None

    rows = await get_query_results(
        """
        SELECT school_id, status FROM school.school_users
        WHERE school_user_id = %s
        LIMIT 1
        """,
        (x_school_user_id,),
    )
    if not rows:
        raise HTTPException(status_code=401, detail="Unknown school user")
    me = rows[0]
    if me.get('status') != 'active':
        raise HTTPException(status_code=403, detail="Account suspended")

    if requested_school_id is not None and me['school_id'] != requested_school_id:
        raise HTTPException(
            status_code=403,
            detail=f"Caller does not belong to school_id={requested_school_id}",
        )
    return x_school_user_id
