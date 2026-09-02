import json
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException

from models.auth import SchoolUser
from utils.auth_deps import current_ai_school_user
from utils.db import get_query_results
from utils.generate import (
    generate_words,
    generate_sentences,
    generate_translated_sentence_distractors,
)
from utils.generate_exercise import (
    gen_single_choice_exercise,
    gen_identify_words,
)

from models.edit.generate_poc_new import (
    Course,
    CourseOption,
    CourseWord,
    GenerateForWords,
    Exercise,
    Lesson,
    Sentence,
    Sentences,
)
from models.edit.exercise import ExerciseEdit, ExerciseType, Options

router = APIRouter()


def _default_title(course: Course, school_user: SchoolUser) -> str:
    return (
        f"Course {course.lang or 'Unknown'} to {course.to_lang or 'Unknown'} "
        f"school {school_user.school_name or 'Unknown'} "
        f"{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
    )


def _gen_params(course: Course) -> dict:
    """The generation knobs from a course's options (course_simple.course.metadata),
    unwrapped to the plain str/int values utils/generate.py expects."""
    opts = course.metadata or CourseOption()
    return {
        "content_source": str(opts.content_source.value if opts.content_source else "corpus"),
        "provider": str(opts.provider.value if opts.provider else "ollama"),
        "model": str(opts.model.value if opts.model else "gemma4"),
        "max_words": opts.max_sentences_words or 4,
    }


def _words_json(course: Course) -> str:
    return json.dumps([w.model_dump() for w in (course.words or [])])


def _metadata_json(course: Course) -> str:
    return json.dumps((course.metadata or CourseOption()).model_dump())


async def _update_course(course: Course, school_user: SchoolUser):
    """Persist a course row (meta + options + word list), scoped to the
    signed-in user/school."""
    sql = """
    UPDATE course_simple.course
    SET lang = %s,
        to_lang = %s,
        title = %s,
        description = %s,
        status = %s,
        level = %s,
        metadata = %s,
        words = %s,
        updated_at = now()
    WHERE course_id = %s AND user_id = %s::text AND school_id = %s
    RETURNING course_id
    """
    params = (
        course.lang,
        course.to_lang,
        course.title,
        course.description,
        "published" if course.published else "draft",
        course.level or "",
        _metadata_json(course),
        _words_json(course),
        course.course_id,
        school_user.user_id,
        school_user.school_id,
    )
    return await get_query_results(sql, params)


@router.post("/create_course", response_model=Course)
async def create_course(course: Course, school_user: SchoolUser = Depends(current_ai_school_user)):
    """
    Creates a new course. The `metadata` (CourseOption) block carries the
    generation options — content source, AI provider/model and the
    sentence/exercise knobs — and is stored on the course so every later
    generate_* call can read it back.
    """
    if not course.title:
        course.title = _default_title(course, school_user)

    sql = """
    INSERT INTO course_simple.course
        (lang, to_lang, user_id, school_id, title, description, status, level, metadata, words)
    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
    RETURNING course_id
    """
    params = (
        course.lang,
        course.to_lang,
        school_user.user_id,
        school_user.school_id,
        course.title,
        course.description,
        "draft",
        course.level or "",
        _metadata_json(course),
        _words_json(course),
    )
    rows = await get_query_results(sql, params)
    course.course_id = rows[0]["course_id"] if rows else 0
    return course


@router.post("/update_course", response_model=Course)
async def update_course(course: Course, school_user: SchoolUser = Depends(current_ai_school_user)):
    result = await _update_course(course, school_user)
    if not result:
        raise HTTPException(status_code=404, detail="Course not found")
    return course


@router.post("/generate_words_list", response_model=Course)
async def generate_words_list(
    course: Course,
    count: int = 12,
    school_user: SchoolUser = Depends(current_ai_school_user),
):
    """Generate a words list for a course and append it to course.words,
    then persist. Uses the course's own options for content source /
    provider / model."""
    p = _gen_params(course)
    words_so_far = [w.word for w in (course.words or [])]
    words = await generate_words(
        course.lang,
        course.to_lang,
        words_so_far=words_so_far,
        level=course.level,
        content_source=p["content_source"],
        provider=p["provider"],
        model=p["model"],
        max_words=count,
    )
    weight = max((w.weight for w in (course.words or [])), default=0)
    for w in words:
        weight += 1
        course.words.append(CourseWord(word=w, weight=weight, used=0))
    await _update_course(course, school_user)
    return course


@router.post("/sentences_for_word", response_model=list[Sentence])
async def sentences_for_word(generate: GenerateForWords, school_user: SchoolUser = Depends(current_ai_school_user)):
    """
    Returns a list of sentences for the requested words, spreading
    `num_elements` sentences across them.
    """
    course = generate.course
    words = generate.words
    p = _gen_params(course)
    results: list[Sentence] = []
    per_word = max(1, generate.num_elements // max(1, len(words)))
    for i, w in enumerate(words):
        if i == len(words) - 1:
            num_sentences = generate.num_elements - len(results)
        else:
            num_sentences = per_word
        sentences = await generate_sentences(
            lang=course.lang,
            to_lang=course.to_lang,
            word=w,
            level=course.level,
            content_source=p["content_source"],
            provider=p["provider"],
            model=p["model"],
            max_words=p["max_words"],
            num_sentences=num_sentences,
        )
        results.extend([Sentence(sentences=s, word=w) for s in sentences])
    return results


@router.post("/exercise_for_word", response_model=list[ExerciseEdit])
async def exercise_for_word(generate: GenerateForWords, school_user: SchoolUser = Depends(current_ai_school_user)):
    """
    Create single-choice exercises for the requested words, from
    translated sentences + AI/corpus distractors.
    """
    course = generate.course
    words = generate.words
    p = _gen_params(course)
    per_word = max(1, generate.num_elements // max(1, len(words)))
    exercises: list[ExerciseEdit] = []
    for i, w in enumerate(words):
        if i == len(words) - 1:
            num_sentences = generate.num_elements - len(exercises)
        else:
            num_sentences = per_word
        rows = await generate_translated_sentence_distractors(
            lang=course.lang,
            to_lang=course.to_lang,
            word=w,
            level=course.level,
            content_source=p["content_source"],
            provider=p["provider"],
            model=p["model"],
            max_words=p["max_words"],
            num_sentences=num_sentences,
        )
        for s in rows:
            sentence = s.get("sentence") or s.get(course.lang)
            translation = s.get("translation") or s.get(course.to_lang)
            distractors = s.get("distractors") or []
            exercises.append(
                gen_single_choice_exercise(
                    sentence=sentence,
                    to_sentence=translation,
                    options=distractors,
                )
            )
    return exercises
