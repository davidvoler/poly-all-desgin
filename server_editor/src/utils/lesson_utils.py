from models.lesson import Lesson, LessonFull
from models.exercise import Exercise
from utils.db import get_query_results
from utils.exercise_utils import get_lesson_exercises

async def create_lesson(lesson: Lesson) -> Lesson:
    sql = """
    INSERT INTO course.lesson (course_id, module_id, title, description, deleted, weight, video_start, video_end)
    VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
    RETURNING lesson_id, course_id, module_id, title, description, deleted, weight, video_start, video_end
    """
    values = (lesson.course_id, lesson.module_id, lesson.title, lesson.description, lesson.deleted, lesson.weight,
              lesson.video_start, lesson.video_end)
    row = await get_query_results(sql, values)
    return Lesson(**row[0])

async def get_lesson_full(lesson_id: int) -> LessonFull:
    sql = """
    SELECT lesson_id, course_id, module_id, title, description, deleted, weight, video_start, video_end
    FROM course.lesson
    WHERE lesson_id = %s
    """
    values = (lesson_id,)
    row = await get_query_results(sql, values)
    lesson = Lesson(**row[0])
    exercise = await get_lesson_exercises(lesson_id)
    return LessonFull(lesson=lesson, exercises=exercise)


async def get_lesson(lesson_id: int) -> Lesson:
    sql = """
    SELECT lesson_id, course_id, module_id, title, description, deleted, weight, video_start, video_end
    FROM course.lesson
    WHERE lesson_id = %s
    """
    values = (lesson_id,)
    row = await get_query_results(sql, values)
    return Lesson(**row[0])

async def get_module_lessons(module_id: int) -> list[Lesson]:
    sql = """
    SELECT lesson_id, course_id, module_id, title, description, deleted, weight, video_start, video_end
    FROM course.lesson
    WHERE module_id = %s
    ORDER BY weight, lesson_id
    """
    values = (module_id,)
    rows = await get_query_results(sql, values)
    return [Lesson(**row) for row in rows]


async def get_module_lesson_full(module_id: int) -> list[LessonFull]:
    sql = """
    SELECT lesson_id, course_id, module_id, title, description, deleted, weight, video_start, video_end
    FROM course.lesson
    WHERE module_id = %s
    ORDER BY weight, lesson_id
    """
    values = (module_id,)
    rows = await get_query_results(sql, values)
    lessons_full = []
    for row in rows:
        lesson = Lesson(**row)
        exercise = await get_lesson_exercises(lesson.lesson_id)
        lessons_full.append(LessonFull(lesson=lesson, exercises=exercise))
    return lessons_full

async def update_lesson(lesson: Lesson) -> Lesson:
    sql = """
    UPDATE course.lesson
    SET module_id = %s, title = %s, description = %s, deleted = %s, weight = %s
    WHERE lesson_id = %s
    RETURNING lesson_id, course_id, module_id, title, description, deleted, weight, video_start, video_end
    """
    values = (lesson.module_id, lesson.title, lesson.description, lesson.deleted, lesson.weight, lesson.lesson_id)
    row = await get_query_results(sql, values)
    return Lesson(**row[0])

async def delete_lesson(lesson: Lesson) -> None:
    sql = """
    DELETE FROM course.lesson
    WHERE lesson_id = %s
    """
    values = (lesson.lesson_id,)
    await get_query_results(sql, values)