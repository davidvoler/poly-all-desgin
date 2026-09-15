import json

from pydantic import BaseModel, field_validator


class Exercise(BaseModel):
    exercise_id: int | None = None
    course_id: int | None = None
    module_id: int | None = None
    lesson_id: int | None = None
    exercise_type: str | None = None
    question: str | None = None
    options: dict | None = None
    explanation: str | None = None
    sentence_alt1: str | None = None
    sentence_alt2: str | None = None
    sentence_alt3: str | None = None
    ruby_text: dict | None = None
    annotations: list | None = None
    answer: str | None = None
    weight: int | None = 0

    # options / ruby_text / annotations are jsonb and, per historical upload
    # runs, can come back as a real object/array, a double-encoded JSON
    # string, or null - coerce them to their canonical shape.
    @field_validator("options", "ruby_text", mode="before")
    @classmethod
    def _coerce_jsonb_dict(cls, v):
        if v is None:
            return None
        if isinstance(v, str):
            try:
                v = json.loads(v)
            except (ValueError, TypeError):
                return None
        return v if isinstance(v, dict) else None

    @field_validator("annotations", mode="before")
    @classmethod
    def _coerce_annotations(cls, v):
        if v is None:
            return None
        if isinstance(v, str):
            try:
                v = json.loads(v)
            except (ValueError, TypeError):
                return None
        return v if isinstance(v, list) else None
