import json
from datetime import datetime

from pydantic import BaseModel, field_validator


class Course(BaseModel):
    course_id: int | None = None
    school: str | None = None
    user_id: int | None = None
    lang: str | None = None
    to_lang: str | None = None
    level: str | None = None
    title: str | None = None
    description: str | None = None
    deleted: bool | None = False
    status: str | None = None  # draft, reviewed, published, archived
    course_options: dict | None = None
    created_at: datetime | None = None
    updated_at: datetime | None = None

    # course_options is jsonb and, like other jsonb columns in this schema,
    # can come back as a real object, a double-encoded JSON string, or null.
    @field_validator("course_options", mode="before")
    @classmethod
    def _coerce_course_options(cls, v):
        if v is None:
            return None
        if isinstance(v, str):
            try:
                v = json.loads(v)
            except (ValueError, TypeError):
                return None
        return v if isinstance(v, dict) else None
