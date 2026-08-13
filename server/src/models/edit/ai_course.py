import json

from pydantic import BaseModel


# --- Words -----------------------------------------------------------
# Words are not a database entity — course_simple.course.words is a
# plain ordered jsonb list (AI-generated order = simplest/most common
# word first). There's no id to create/delete by; the word string
# itself is the identity, same as course_simple.lesson.words already is.

class CourseWord(BaseModel):
    word: str
    gloss: str | None = ''
    example_sentence: str | None = ''
    example_gloss: str | None = ''
    used: bool = False


class WordAddRequest(BaseModel):
    course_id: int
    word: str
    gloss: str | None = ''


class WordRemoveRequest(BaseModel):
    course_id: int
    word: str


# --- Sentences ---------------------------------------------------------
# Sentences ARE a database entity (course_simple.sentence), but nothing
# holds a foreign key to them. sentence_id is a deterministic hash of
# "lang:text" (utils.ai_course_content.sentence_id_for), computed in
# application code — so a lesson or exercise just carries that id inline
# (matching the pre-existing, never FK-enforced
# course_simple.exercise.sentence_id/to_sentence_id columns) with no
# join needed in either direction.

class LessonSentenceOut(BaseModel):
    sentence_id: int
    word: str | None = None
    text: str
    gloss: str | None = ''
    chosen: bool = True


class ExerciseOut(BaseModel):
    exercise_id: int
    lesson_id: int
    sentence_id: int | None = None
    exercise_type: str
    prompt: str
    options: list[str] = []
    answer: str | None = None


def exercise_from_row(row: dict) -> ExerciseOut:
    """`course_simple.exercise` has no `prompt`-shaped column of its own —
    this maps the AI-copilot's fields onto the existing ones: `sentence`
    holds the exercise prompt text, `options` jsonb holds the option
    list, `answer` (added in create_with_ai_v2.sql) holds the correct
    option string."""
    options = row.get("options") or []
    if isinstance(options, str):
        options = json.loads(options)
    return ExerciseOut(
        exercise_id=row["exercise_id"],
        lesson_id=row["lesson_id"],
        sentence_id=row.get("sentence_id"),
        exercise_type=row["exercise_type"],
        prompt=row.get("sentence") or "",
        options=options,
        answer=row.get("answer"),
    )


class LessonOut(BaseModel):
    lesson_id: int
    module_id: int
    course_id: int
    title: str
    status: str
    words: list[str] = []
    sentences: list[LessonSentenceOut] = []
    exercises: list[ExerciseOut] = []


class ModuleFull(BaseModel):
    module_id: int
    title: str
    lessons: list[LessonOut] = []


class CourseFull(BaseModel):
    course_id: int
    title: str
    description: str | None = ''
    lang: str
    to_lang: str
    level: str
    words: list[CourseWord] = []
    modules: list[ModuleFull] = []
