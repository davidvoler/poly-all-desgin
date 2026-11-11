from pydantic import BaseModel

from models.context import PromptsContext
from models.prompts import PromptOption, PromptRouterType, PromptType
from utils.context_utils import get_or_create_context
from utils.exercise_utils import get_lesson_exercises
from utils.lesson_utils import get_module_lessons
from utils.words_utils import course_words

# When a lesson has this many exercises, the next ones go to a new lesson.
MAX_EXERCISES_PER_LESSON = 10
# When a module has this many lessons (and the last is full), continue in a new module.
MAX_LESSONS_PER_MODULE = 5
# Words turned into exercises by one request, to keep the AI call short.
EXERCISES_PER_REQUEST = 3
# Exercise options offered at once, each for different unused words.
EXERCISE_OPTIONS = 3


class ContextStats(BaseModel):
    context: PromptsContext
    words: int
    unused_words: list[str]
    lessons: int
    lesson_exercises: int

    @property
    def lesson_full(self) -> bool:
        return self.lesson_exercises >= MAX_EXERCISES_PER_LESSON

    @property
    def module_full(self) -> bool:
        return self.lesson_full and self.lessons >= MAX_LESSONS_PER_MODULE


async def context_stats(course_id: int) -> ContextStats:
    """What the course's current module and lesson hold."""
    context = await get_or_create_context(course_id)
    words = await course_words(context.course_id, context.module_id)
    return ContextStats(
        context=context,
        words=len(words),
        unused_words=[w.text for w in words if not w.used],
        lessons=len(await get_module_lessons(context.module_id)),
        lesson_exercises=len(await get_lesson_exercises(context.lesson_id)),
    )


def _option(stats: ContextStats, text: str, router_type: PromptRouterType,
            prompt_type: PromptType, comment: str) -> PromptOption:
    c = stats.context
    return PromptOption(
        course_id=c.course_id, module_id=c.module_id, lesson_id=c.lesson_id,
        option_text=text, router_type=router_type, prompt_type=prompt_type,
        comment=comment, is_option=True,
    )


async def _video_options(stats: ContextStats) -> list[PromptOption] | None:
    """For a video module: how to split the video, else the next part to extract.
    None when the module has no video."""
    # Imported here: prompt_routers.video imports this module's helpers indirectly.
    from prompt_routers.video import extract_options, part_exercise_options, split_options
    from utils.video_utils import (
        count_parts, get_module_video, next_part_to_extract, next_part_with_exercise_material)
    c = stats.context
    video = await get_module_video(c.module_id)
    if not video:
        return None
    parts, _ = await count_parts(c.module_id)
    if not parts:
        return split_options(c.course_id, c.module_id, video[1])
    options = []
    material = await next_part_with_exercise_material(c.module_id)
    if material:
        options += part_exercise_options(c.course_id, c.module_id, *material)
    part = await next_part_to_extract(c.module_id)
    if part:
        options += extract_options(c.course_id, c.module_id, part.title)
    return options


async def context_options(course_id: int) -> list[PromptOption]:
    """The next steps that fit the course's current module and lesson."""
    if not course_id:
        return []
    stats = await context_stats(course_id)
    unused = len(stats.unused_words)
    video_options = await _video_options(stats)
    if video_options is not None and stats.context.lesson_id == 0:
        return video_options  # the video is not split yet
    is_video = video_options is not None
    options = video_options or []
    # A video module's lessons are its parts, so no lessons or modules are added after it.
    if not is_video and stats.module_full:
        options.append(_option(
            stats, f"Create the next module (moves {unused} unused words)", PromptRouterType.MODULE,
            PromptType.MODULE_CREATE,
            f"The module has {stats.lessons} lessons; continue in a new module with the words not used yet."))
    elif not is_video and stats.lesson_full:
        options.append(_option(
            stats, "Create the next lesson", PromptRouterType.LESSON, PromptType.LESSON_CREATE,
            f"The lesson has {stats.lesson_exercises} exercises."))
    # Alternatives, each naming its own unused words; the option carries them in prompt_values.
    # A video module makes its exercises from its parts instead.
    size = min(EXERCISES_PER_REQUEST, MAX_EXERCISES_PER_LESSON - stats.lesson_exercises)
    if size > 0 and not is_video:
        for start in range(0, min(unused, size * EXERCISE_OPTIONS), size):
            words = stats.unused_words[start:start + size]
            option = _option(
                stats, f"Create single choice exercises for: {', '.join(words)}", PromptRouterType.EXERCISE,
                PromptType.EXERCISE_SINGLE_CHOICE, f"{unused} words are not used in an exercise yet.")
            option.prompt_values = words
            options.append(option)
    # A video module gets its words from its parts first.
    if not unused and not (is_video and video_options):
        options.append(_option(
            stats, "Suggest words" if stats.words == 0 else "Suggest more words",
            PromptRouterType.VOCABULARY, PromptType.VOCABULARY_SUGGEST_WORDS,
            "The module has no words yet." if stats.words == 0 else "All the module's words are used."))
    return options
