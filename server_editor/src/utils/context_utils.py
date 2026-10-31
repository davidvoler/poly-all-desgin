import asyncio
from collections import defaultdict

from models.context import PromptsContext
from models.lesson import Lesson
from models.module import Module
from utils.db import get_query_results
from utils.lesson_utils import create_lesson, get_module_lessons
from utils.module_utils import create_module, get_course_modules
from utils.video_utils import get_module_video
from utils.words_utils import course_words

async def save_context(context: PromptsContext) -> PromptsContext:
    sql = """
    INSERT INTO course.prompt_context (course_id, module_id, lesson_id)
    VALUES (%s, %s, %s)
    RETURNING context_id, course_id, module_id, lesson_id
    """
    params = (context.course_id, context.module_id, context.lesson_id)
    results = await get_query_results(sql, params)
    pc = PromptsContext(**results[0])
    if context.words:
        pc.words = context.words
    else:
        pc.words = await course_words(course_id=pc.course_id, module_id=pc.module_id)
    return pc

# One lock per course: the course pane and the chat ask for a new course's context at
# the same time, and without it each would create its own first module and lesson.
_course_locks: defaultdict[int, asyncio.Lock] = defaultdict(asyncio.Lock)


async def get_or_create_context(course_id: int, module_id: int = 0, lesson_id: int = 0) -> PromptsContext:
    if course_id == 0:
        return PromptsContext(course_id=0, module_id=0, lesson_id=0)
    async with _course_locks[course_id]:
        return await _get_or_create_context(course_id, module_id, lesson_id)


async def _get_or_create_context(course_id: int, module_id: int, lesson_id: int) -> PromptsContext:
    # The last saved context of the course, or of the module when one is given.
    if module_id > 0:
        whr = "course_id = %s AND module_id = %s"
        params = (course_id, module_id)
    else:
        whr = "course_id = %s"
        params = (course_id,)
    sql = f"""
    SELECT context_id, course_id, module_id, lesson_id
    FROM course.prompt_context WHERE {whr}
    ORDER BY context_id DESC
    LIMIT 1
    """
    results = await get_query_results(sql, params)
    if results:
        pc = PromptsContext(**results[0])
        if pc.module_id > 0 and pc.lesson_id > 0:
            pc.words = await course_words(course_id=pc.course_id, module_id=pc.module_id)
            return pc
    else:
        pc = PromptsContext(course_id=course_id, module_id=module_id, lesson_id=lesson_id)
    # Fill what is missing with the first module/lesson, creating them when there is none.
    if pc.module_id == 0:
        modules = await get_course_modules(pc.course_id)
        module = modules[0] if modules else await create_module(Module(course_id=pc.course_id, title="Module 1"))
        pc.module_id = module.module_id
    if pc.lesson_id == 0:
        lessons = await get_module_lessons(pc.module_id)
        if not lessons and await get_module_video(pc.module_id):
            # A video module gets its lessons when the video is split into parts.
            pc.words = await course_words(course_id=pc.course_id, module_id=pc.module_id)
            return pc
        lesson = lessons[0] if lessons else await create_lesson(
            Lesson(course_id=pc.course_id, module_id=pc.module_id, title="Lesson 1")
        )
        pc.lesson_id = lesson.lesson_id
    return await save_context(pc)
