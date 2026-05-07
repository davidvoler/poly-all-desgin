"""Polyglots API — minimal FastAPI server with Courses + Course endpoints.

Sample data mirrors what the Flutter client currently hard-codes for the
`Japanese for Beginners` flow. Run with:

    uv run uvicorn main:app --reload --port 8000

Then:
    curl http://localhost:8000/courses
    curl http://localhost:8000/courses/japanese-beginners
"""

from enum import Enum
from typing import Optional

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field


# ──────────────────────────── Models ────────────────────────────


class Lang(str, Enum):
    en = "en"
    ja = "ja"
    he = "he"
    ar = "ar"
    it = "it"
    el = "el"


class ModuleState(str, Enum):
    done = "done"
    selected = "selected"  # in-progress / current
    locked = "locked"


class Lesson(BaseModel):
    id: str
    native: str
    translation: str
    done: bool = False
    selected: bool = False  # the user's current lesson


class Module(BaseModel):
    id: str
    name: str
    lesson_count: int
    completed_count: int
    state: ModuleState
    # Only populated for the currently-selected module; others omit
    # lessons to keep summary calls light.
    lessons: list[Lesson] = Field(default_factory=list)


class CourseSummary(BaseModel):
    """Shape used by the courses list (`GET /courses`)."""

    id: str
    title: str
    subtitle: str
    icon: str = "play_arrow"        # material icon name (matches client)
    level_pill: str                  # e.g. "A1·A2", "In Progress"
    source_lang: Lang                # what the learner speaks
    target_lang: Lang                # what they're learning
    in_progress: bool = False
    progress: Optional[float] = None  # 0..1, only when in_progress
    footer: Optional[str] = None      # e.g. "18 lessons · 145 phrases"


class CourseDetail(CourseSummary):
    """Shape used by `GET /courses/{course_id}` — adds module breakdown."""

    total_lessons: int
    completed_lessons: int
    total_words: int
    modules: list[Module]


# ──────────────────────────── Sample data ────────────────────────────


_LESSONS_M3: list[Lesson] = [
    Lesson(id="m3-l1", native="はじめまして", translation="Nice to meet you", done=True),
    Lesson(id="m3-l2", native="わたしは", translation="I am…", done=True),
    Lesson(id="m3-l3", native="どうぞよろしく", translation="Pleased to meet you", done=True),
    Lesson(id="m3-l4", native="お名前は何ですか", translation="What is your name?", selected=True),
]

_BEGINNERS_MODULES: list[Module] = [
    Module(id="m1", name="First Words", lesson_count=4, completed_count=4, state=ModuleState.done),
    Module(id="m2", name="Numbers & Colors", lesson_count=5, completed_count=5, state=ModuleState.done),
    Module(
        id="m3",
        name="Greetings & Introductions",
        lesson_count=4,
        completed_count=3,
        state=ModuleState.selected,
        lessons=_LESSONS_M3,
    ),
    Module(id="m4", name="Family & People", lesson_count=5, completed_count=0, state=ModuleState.locked),
    Module(id="m5", name="Food & Drink", lesson_count=6, completed_count=0, state=ModuleState.locked),
]

_COURSES: list[CourseDetail] = [
    CourseDetail(
        id="japanese-beginners",
        title="Japanese for Beginners",
        subtitle="First words, greetings, numbers",
        icon="play_arrow",
        level_pill="In Progress",
        source_lang=Lang.en,
        target_lang=Lang.ja,
        in_progress=True,
        progress=0.45,
        footer="45% · 12/24",
        total_lessons=24,
        completed_lessons=12,
        total_words=248,
        modules=_BEGINNERS_MODULES,
    ),
    CourseDetail(
        id="travel-phrases",
        title="Travel Phrases",
        subtitle="Directions, food, hotels",
        icon="flight_takeoff",
        level_pill="A1·A2",
        source_lang=Lang.en,
        target_lang=Lang.ja,
        footer="18 lessons · 145 phrases",
        total_lessons=18,
        completed_lessons=0,
        total_words=145,
        modules=[],
    ),
    CourseDetail(
        id="kana",
        title="Hiragana & Katakana",
        subtitle="Master both kana scripts",
        icon="menu_book",
        level_pill="A1",
        source_lang=Lang.en,
        target_lang=Lang.ja,
        footer="14 lessons · 92 characters",
        total_lessons=14,
        completed_lessons=0,
        total_words=92,
        modules=[],
    ),
    CourseDetail(
        id="japanese-business",
        title="Japanese for Business",
        subtitle="Keigo, meetings, email etiquette",
        icon="work",
        level_pill="B1·B2",
        source_lang=Lang.en,
        target_lang=Lang.ja,
        footer="22 lessons · 280 phrases",
        total_lessons=22,
        completed_lessons=0,
        total_words=280,
        modules=[],
    ),
    CourseDetail(
        id="everyday-conversation",
        title="Everyday Conversation",
        subtitle="Real dialogues, casual speech",
        icon="forum",
        level_pill="A2·B1",
        source_lang=Lang.en,
        target_lang=Lang.ja,
        footer="20 lessons · 320 phrases",
        total_lessons=20,
        completed_lessons=0,
        total_words=320,
        modules=[],
    ),
]

_BY_ID: dict[str, CourseDetail] = {c.id: c for c in _COURSES}


# ──────────────────────────── App ────────────────────────────


app = FastAPI(
    title="Polyglots API",
    version="0.1.0",
    description="Backend for the Polyglots learning app.",
)

# Permissive CORS for local dev — Flutter web hits this, mobile doesn't care.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health", tags=["meta"])
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/courses", response_model=list[CourseSummary], tags=["courses"])
def list_courses(
    source: Optional[Lang] = Query(None, description="Filter by 'I speak' language"),
    target: Optional[Lang] = Query(None, description="Filter by 'Learning' language"),
) -> list[CourseSummary]:
    """List available courses, optionally filtered by language pair."""
    courses = _COURSES
    if source is not None:
        courses = [c for c in courses if c.source_lang == source]
    if target is not None:
        courses = [c for c in courses if c.target_lang == target]
    # FastAPI handles the response_model coercion; CourseDetail → CourseSummary
    # drops the extra fields (modules, totals).
    return courses


@app.get("/courses/{course_id}", response_model=CourseDetail, tags=["courses"])
def get_course(course_id: str) -> CourseDetail:
    """Full course detail including modules and the current module's lessons."""
    course = _BY_ID.get(course_id)
    if course is None:
        raise HTTPException(status_code=404, detail=f"Course '{course_id}' not found")
    return course
