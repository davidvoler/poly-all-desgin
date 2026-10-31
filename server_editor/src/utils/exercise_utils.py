import json
from models.exercise import Exercise
from utils.db import get_query_results, run_query

EXERCISE_COLUMNS = """exercise_id, course_id, module_id, lesson_id, exercise_type, word, question,
    options, explanation, sentence_alt1, sentence_alt2, sentence_alt3, ruby_text, annotations, answer, weight"""

# Columns written on create/update, in this order.
_EDITABLE = ("course_id", "module_id", "lesson_id", "exercise_type", "word", "question", "options",
             "explanation", "sentence_alt1", "sentence_alt2", "sentence_alt3", "ruby_text",
             "annotations", "answer", "weight")


def _values(exercise: Exercise) -> tuple:
    data = exercise.model_dump(mode="json")
    json_columns = ("options", "ruby_text", "annotations")
    return tuple(
        json.dumps(data[c]) if c in json_columns and data[c] is not None else data[c]
        for c in _EDITABLE
    )


async def mark_module_words_used(module_id: int) -> None:
    """A module's word is used when one of the module's exercises practises it."""
    sql = """
    UPDATE course.words w
    SET used = EXISTS (
        SELECT 1 FROM course.exercise e
        WHERE e.module_id = w.module_id AND e.word = w.word
    )
    WHERE w.module_id = %s
    """
    await run_query(sql, (module_id,))


async def _fill_from_lesson(exercise: Exercise) -> None:
    """Exercises are saved with their lesson's module and course."""
    if exercise.lesson_id and not (exercise.module_id and exercise.course_id):
        rows = await get_query_results(
            "SELECT course_id, module_id FROM course.lesson WHERE lesson_id = %s", (exercise.lesson_id,)
        )
        if rows:
            exercise.course_id = exercise.course_id or rows[0]["course_id"]
            exercise.module_id = exercise.module_id or rows[0]["module_id"]


async def create_exercise(exercise: Exercise) -> Exercise:
    await _fill_from_lesson(exercise)
    sql = f"""
    INSERT INTO course.exercise ({", ".join(_EDITABLE)})
    VALUES ({", ".join(["%s"] * len(_EDITABLE))})
    RETURNING {EXERCISE_COLUMNS}
    """
    row = await get_query_results(sql, _values(exercise))
    created = Exercise(**row[0])
    if created.module_id:
        await mark_module_words_used(created.module_id)
    return created

async def get_exercise(exercise_id: int) -> Exercise:
    sql = f"""
    SELECT {EXERCISE_COLUMNS}
    FROM course.exercise
    WHERE exercise_id = %s
    """
    row = await get_query_results(sql, (exercise_id,))
    return Exercise(**row[0])

async def get_lesson_exercises(lesson_id: int) -> list[Exercise]:
    sql = f"""
    SELECT {EXERCISE_COLUMNS}
    FROM course.exercise
    WHERE lesson_id = %s
    ORDER BY weight, exercise_id
    """
    rows = await get_query_results(sql, (lesson_id,))
    return [Exercise(**row) for row in rows]

async def update_exercise(exercise: Exercise) -> Exercise:
    await _fill_from_lesson(exercise)
    previous = await get_exercise(exercise.exercise_id)
    sql = f"""
    UPDATE course.exercise
    SET {", ".join(f"{c} = %s" for c in _EDITABLE)}
    WHERE exercise_id = %s
    RETURNING {EXERCISE_COLUMNS}
    """
    row = await get_query_results(sql, (*_values(exercise), exercise.exercise_id))
    updated = Exercise(**row[0])
    for module_id in {previous.module_id, updated.module_id} - {None}:
        await mark_module_words_used(module_id)
    return updated

async def delete_exercise(exercise_id: int) -> None:
    rows = await get_query_results(
        "DELETE FROM course.exercise WHERE exercise_id = %s RETURNING module_id", (exercise_id,)
    )
    if rows and rows[0]["module_id"]:
        await mark_module_words_used(rows[0]["module_id"])
