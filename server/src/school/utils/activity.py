"""Shared writer for the school.activity_log feed.

Every dashboard write-endpoint that should surface in the Overview
"Recent activity" panel funnels through here so the INSERT and its
column names stay in one place. The dashboard already maps `kind` to
a dot color, so use the strings the front-end recognises:

  - course_upload, course_published, course_review_submitted,
    course_archived, course_returned_to_draft  → green dot
  - editor_invite, editor_added                → orange dot
  - everything else                            → blue dot
"""
from utils.db import run_query


async def log_activity(
    *,
    school_id: int,
    kind: str,
    summary: str,
    actor_user_id: int | None = None,
) -> None:
    await run_query(
        """
        INSERT INTO school.activity_log
            (school_id, actor_user_id, kind, summary)
        VALUES (%s, %s, %s, %s)
        """,
        (school_id, actor_user_id, kind, summary),
    )
