"""Defensive jsonb coercion. course_simple jsonb list columns come back
from psycopg as parsed Python lists most of the time, but have
historically also shown up as double-encoded JSON strings or null (see
models/course.py's Exercise.annotations/ruby_text) — same defense here
for course.words / lesson.sentences."""
import json


def coerce_json_list(v) -> list:
    if v is None:
        return []
    if isinstance(v, str):
        try:
            v = json.loads(v)
        except (ValueError, TypeError):
            return []
    return v if isinstance(v, list) else []
