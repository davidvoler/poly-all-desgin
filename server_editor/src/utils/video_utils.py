import json
import random
import math

import httpx
from youtube_transcript_api._errors import CouldNotRetrieveTranscript

from models.lesson import Lesson
from models.video import Subtitle
from utils.db import get_query_results, run_query
from utils.lesson_utils import create_lesson
from utils.subtitle import break_subtitles_into_sections, youtube_id_from_url, youtube_subs, ytt_api

# Part lengths offered when splitting a video, in seconds.
PART_LENGTHS = (180, 120)


class VideoError(Exception):
    """A video that cannot be used, with a message for the user."""


def find_video_url(text: str) -> str | None:
    """The first YouTube URL in a message, if any."""
    for token in text.split():
        if youtube_id_from_url(token):
            return token
    return None


async def video_title(url: str) -> str | None:
    """The video's title from YouTube's oEmbed endpoint; None when unavailable."""
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            response = await client.get("https://www.youtube.com/oembed", params={"url": url, "format": "json"})
        return response.json().get("title") if response.status_code == 200 else None
    except (httpx.HTTPError, ValueError):
        return None


def fetch_subtitles(url: str, lang: str) -> list[Subtitle]:
    """The video's subtitles in lang. Raises VideoError when there are none."""
    video_id = youtube_id_from_url(url)
    if not video_id:
        raise VideoError("That does not look like a YouTube video link.")
    try:
        return youtube_subs(video_id, lang)
    except CouldNotRetrieveTranscript:
        try:
            available = sorted({t.language_code for t in ytt_api.list(video_id)})
        except CouldNotRetrieveTranscript:
            available = []
        raise VideoError(
            f"The video has no subtitles in '{lang}'."
            + (f" Available: {', '.join(available)}." if available else " It has no subtitles at all.")
        )


def video_seconds(subtitles: list[Subtitle]) -> float:
    return max((s.start + s.duration for s in subtitles), default=0)


def part_counts(subtitles: list[Subtitle]) -> list[tuple[int, int]]:
    """(part length in seconds, number of parts) for each offered length."""
    seconds = video_seconds(subtitles)
    return [(length, max(1, math.ceil(seconds / length))) for length in PART_LENGTHS]


async def save_video(course_id: int, module_id: int, lang: str, url: str, subtitles: list[Subtitle]) -> int:
    rows = await get_query_results(
        """INSERT INTO course.video (course_id, module_id, lang, url, raw_subtitles)
        VALUES (%s, %s, %s, %s, %s) RETURNING video_id""",
        (course_id, module_id, lang, url, json.dumps([s.model_dump() for s in subtitles])),
    )
    return rows[0]["video_id"]


async def get_module_video(module_id: int) -> tuple[str, list[Subtitle]] | None:
    """The module's video URL and subtitles, or None when it is not a video module."""
    rows = await get_query_results(
        """SELECT url, raw_subtitles FROM course.video
        WHERE module_id = %s AND deleted IS NOT TRUE ORDER BY video_id DESC LIMIT 1""",
        (module_id,),
    )
    if not rows:
        return None
    return rows[0]["url"], [Subtitle(**s) for s in json.loads(rows[0]["raw_subtitles"] or "[]")]


def _clock(seconds: float) -> str:
    return f"{int(seconds // 60)}:{int(seconds % 60):02d}"


async def create_parts(course_id: int, module_id: int, subtitles: list[Subtitle], part_seconds: int) -> list[Lesson]:
    """One lesson per part of the video; the lesson's description holds the part's text."""
    sections = break_subtitles_into_sections(subtitles, part_seconds)
    lessons = []
    for index, section in enumerate(sections):
        lessons.append(await create_lesson(Lesson(
            course_id=course_id, module_id=module_id, weight=index,
            title=f"Part {index + 1} ({_clock(section.start)}-{_clock(section.end)})",
            description=section.text, video_start=section.start, video_end=section.end,
        )))
    return lessons


async def next_part_to_extract(module_id: int) -> Lesson | None:
    """The first part whose words and sentences are not extracted yet."""
    rows = await get_query_results(
        """SELECT lesson_id, course_id, module_id, title, description, deleted, weight, video_start, video_end
        FROM course.lesson
        WHERE module_id = %s AND words IS NULL AND COALESCE(description, '') <> ''
        ORDER BY weight, lesson_id LIMIT 1""",
        (module_id,),
    )
    return Lesson(**rows[0]) if rows else None


async def count_parts(module_id: int) -> tuple[int, int]:
    """(parts, parts already extracted) of a video module."""
    rows = await get_query_results(
        """SELECT count(*) AS parts, count(words) AS extracted FROM course.lesson
        WHERE module_id = %s AND COALESCE(description, '') <> ''""",
        (module_id,),
    )
    return rows[0]["parts"], rows[0]["extracted"]


async def mark_part_extracted(lesson_id: int, words: list[str]) -> None:
    await run_query("UPDATE course.lesson SET words = %s WHERE lesson_id = %s", ([w[:100] for w in words], lesson_id))


async def save_sentences(lang: str, course_id: int, module_id: int, lesson_id: int,
                         sentences: list[tuple[str, str]]) -> None:
    for sentence, translation in sentences:
        await run_query(
            """INSERT INTO course.sentences (lang, course_id, module_id, lesson_id, sentence, translation)
            VALUES (%s, %s, %s, %s, %s, %s)""",
            (lang, course_id, module_id, lesson_id, sentence[:355], translation),
        )


# Wrong options in exercises made from a part's words and sentences.
PART_WRONG_OPTIONS = 3


async def part_words_without_exercises(lesson_id: int, module_id: int) -> list[tuple[str, str]]:
    """(word, translation) for the part's extracted words that no exercise uses yet."""
    rows = await get_query_results(
        """SELECT w.word, min(w.translation) AS translation
        FROM course.lesson l
        JOIN course.words w ON w.module_id = l.module_id AND w.word = ANY(l.words)
        WHERE l.lesson_id = %s AND w.module_id = %s AND w.deleted IS NOT TRUE
          AND COALESCE(w.translation, '') <> ''
        GROUP BY w.word
        HAVING NOT bool_or(COALESCE(w.used, false))
        ORDER BY min(w.word_id)""",
        (lesson_id, module_id),
    )
    return [(r["word"], r["translation"]) for r in rows]


async def part_sentences_without_exercises(lesson_id: int, module_id: int) -> list[tuple[str, str]]:
    """(sentence, translation) for the part's sentences that are not an exercise question yet."""
    rows = await get_query_results(
        """SELECT s.sentence, s.translation FROM course.sentences s
        WHERE s.lesson_id = %s AND COALESCE(s.translation, '') <> ''
          AND NOT EXISTS (SELECT 1 FROM course.exercise e
                          WHERE e.module_id = %s AND e.question = s.sentence)
        ORDER BY s.sentence_id""",
        (lesson_id, module_id),
    )
    return [(r["sentence"], r["translation"]) for r in rows]


async def next_part_with_exercise_material(module_id: int) -> tuple[Lesson, list, list] | None:
    """The first extracted part that still has words or sentences without exercises,
    with those words and sentences."""
    rows = await get_query_results(
        """SELECT lesson_id, course_id, module_id, title, description, deleted, weight, video_start, video_end
        FROM course.lesson WHERE module_id = %s AND words IS NOT NULL
        ORDER BY weight, lesson_id""",
        (module_id,),
    )
    for row in rows:
        words = await part_words_without_exercises(row["lesson_id"], module_id)
        sentences = await part_sentences_without_exercises(row["lesson_id"], module_id)
        if words or sentences:
            return Lesson(**row), words, sentences
    return None


async def module_translations(module_id: int, sentences: bool) -> list[str]:
    """Translations of the module's words, or of its sentences, to draw wrong options from."""
    sql = ("SELECT DISTINCT translation FROM course.sentences WHERE module_id = %s"
           if sentences else
           "SELECT DISTINCT translation FROM course.words WHERE module_id = %s AND deleted IS NOT TRUE")
    rows = await get_query_results(sql, (module_id,))
    return [r["translation"] for r in rows if (r["translation"] or "").strip()]


def random_wrong_options(answer: str, pool: list[str], count: int = PART_WRONG_OPTIONS) -> list[str]:
    """count different translations from pool, none equal to the answer."""
    candidates = list({t.strip() for t in pool if t.strip().lower() != answer.strip().lower()})
    return random.sample(candidates, min(count, len(candidates)))
