import json

from models.auth import SchoolUser
from fastapi import APIRouter, Depends, HTTPException
from utils.auth_deps import current_ai_school_user
from utils.db import get_query_results, run_query
from utils.ai_course_ownership import assert_lesson_owned
from utils.jsonb import coerce_json_list
from utils.ollama_client import OLLAMA_MODELS, OllamaError, ollama_chat
from utils.ai_course_content import (
    exercise_prompt_for_gloss,
    generate_exercise_options,
    # generate_words,
    mock_usage,
    sentence_for_word,
    sentence_id_for,
)
from models.edit.ai_course import CourseWord, ExerciseOut, LessonSentenceOut, exercise_from_row
from models.edit.generate_poc import (
    Prompt,
    PromptResponse,
    PromptResponseOption,
    GenerateCourseRequest,
    GenerateLessonRequest,
    GenerateLessonResponse,
    GenerateWordsRequest,
    GenerateWordsResponse,
    GenerateSentencesRequest,
    GenerateSentencesResponse,
    GenerateExercisesRequest,
    GenerateExercisesResponse,
    PromptType
)

from utils.generate import generate_words

router = APIRouter()


async def create_course(lang, to_lang, user_id, school_id, title, description, level) -> int:
    sql = """INSERT INTO course_simple.course (lang, to_lang, user_id, school_id, title, description, status, level)
    VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
    RETURNING course_id"""
    params = (lang, to_lang, user_id, school_id, title, description, 'draft', level or '')
    result = await get_query_results(sql, params)
    return result[0]['course_id'] if result else 0


def create_title(lang: str | None, to_lang: str | None, user: str | None) -> str:
    return f"Course {lang or 'Unknown'} to  {to_lang or 'Unknown'} speakers "

@router.get("/models")
async def list_models(school_user: SchoolUser = Depends(current_ai_school_user)):
    """Providers + models the "ask AI" chat can send a prompt to (see
    TASKS.md "Claude tasks"). Ollama is the only provider so far — all
    inference is local, so there's no cost associated with any of them."""
    return {"providers": {"ollama": list(OLLAMA_MODELS)}}


@router.post("/", response_model=PromptResponse)
async def generate_poc(request: Prompt, school_user: SchoolUser = Depends(current_ai_school_user)):
    """General-purpose "ask AI anything" prompt (TASKS.md's
    "/generate/prompt - general prompt that we should use AI to
    understand"), backed by a real local model call — as opposed to
    every other generate_poc endpoint below, which is still curated mock
    content (see utils/ai_course_content.py)."""
    if not request.prompt:
        raise HTTPException(status_code=400, detail="prompt is required")
    provider = request.provider or "ollama"
    if provider != "ollama":
        raise HTTPException(status_code=400, detail=f"Unknown provider '{provider}'")
    if request.model and request.model not in OLLAMA_MODELS:
        raise HTTPException(status_code=400, detail=f"Unknown model '{request.model}'. Available: {', '.join(OLLAMA_MODELS)}")
    try:
        result = await ollama_chat(request.prompt, model=request.model)
    except OllamaError as e:
        raise HTTPException(status_code=502, detail=str(e))

    return PromptResponse(
        prompt_type=request.prompt_type,
        prompt=request.prompt,
        response=result["text"],
        course_id=request.course_id,
        lang=request.lang,
        to_lang=request.to_lang,
        actual_tokens=result["prompt_tokens"] + result["response_tokens"],
        actual_cost=0.0,
    )


@router.post("/generate_course", response_model=PromptResponse)
async def generate_course(request: GenerateCourseRequest, school_user: SchoolUser = Depends(current_ai_school_user)):
    """
    Generate a new course based on the provided request.
    """
    if not request.title:
        request.title = create_title(request.lang, request.to_lang, school_user.school_name)
    if not request.description:
        # Handle missing description
        request.description = "No description provided."
    course_id = await create_course(
        request.lang,
        request.to_lang,
        school_user.user_id,
        school_user.school_id,
        request.title,
        request.description,
        request.level,
    )  # Call the function to create a course and get its ID

    prompt_options = [
        PromptResponseOption(
            title="Create Lesson",
            text="Create a new lesson for this course.",
            prompt_type=PromptType.CREATE_LESSON),
        PromptResponseOption(
            title="Get Words List",
            text="Retrieve a list of words for this course.",
            prompt_type=PromptType.GET_WORDS)
    ]
    return PromptResponse(
        options=prompt_options,
        prompt_type=PromptType.CREATE_COURSE,
        prompt=f"Course '{request.title}' created successfully.",
        title=request.title,
        description=request.description,
        course_id=course_id,
        to_lang=request.to_lang,
        lang=request.lang,

        )


@router.post("/generate_words_list", response_model=GenerateWordsResponse)
async def generate_words_list(request: GenerateWordsRequest, school_user: SchoolUser = Depends(current_ai_school_user)):
    """
    Generate a starter word list for a course. Just the words — no
    glossary, no example sentences, and nothing persisted; the caller
    decides what (if anything) to keep.
    """
    course_rows = await get_query_results(
        "SELECT lang, to_lang, level FROM course_simple.course WHERE course_id = %s AND user_id = %s::text AND school_id = %s",
        (request.course_id, school_user.user_id, school_user.school_id),
    )
    if not course_rows:
        raise HTTPException(status_code=404, detail="Course not found")
    lang, to_lang, level = course_rows[0]["lang"], course_rows[0]["to_lang"] or "", course_rows[0]["level"] or ""

    generated = await generate_words(lang, to_lang, [], level, "ai", "ollama", "gemma4", request.count or 12)
    words = [CourseWord(word=w) for w in generated]

    tokens, cost = mock_usage(len(words))
    message = f"Generated {len(words)} starter words for course {request.course_id}."
    return GenerateWordsResponse(
        prompt_type=PromptType.GET_WORDS,
        prompt=message,
        response=message,
        course_id=request.course_id,
        actual_tokens=tokens,
        actual_cost=cost,
        words=words,
    )


async def _lesson_words_with_content(course_id: int, lesson_id: int) -> list[dict]:
    """course.words entries for the words selected on a lesson
    (course_simple.lesson.words text[])."""
    lesson_rows = await get_query_results("SELECT words FROM course_simple.lesson WHERE lesson_id = %s", (lesson_id,))
    selected = (lesson_rows[0]["words"] if lesson_rows else None) or []
    if not selected:
        return []
    course_rows = await get_query_results("SELECT words FROM course_simple.course WHERE course_id = %s", (course_id,))
    all_words = coerce_json_list(course_rows[0].get("words")) if course_rows else []
    by_word = {w["word"]: w for w in all_words}
    return [by_word[w] for w in selected if w in by_word]


async def _generate_and_persist_sentences(course_id: int, lesson_id: int) -> list[dict]:
    """Draft a sentence for each of a lesson's selected words, append
    them to the lesson's own sentences jsonb list, and upsert each into
    course_simple.sentence (a content-addressable cache keyed by
    sentence_id = hash(lang:text) — not a foreign key anything points
    at). Returns just the newly generated entries."""
    course_rows = await get_query_results("SELECT lang FROM course_simple.course WHERE course_id = %s", (course_id,))
    lang = course_rows[0]["lang"] if course_rows else ""
    word_rows = await _lesson_words_with_content(course_id, lesson_id)

    lesson_rows = await get_query_results("SELECT sentences FROM course_simple.lesson WHERE lesson_id = %s", (lesson_id,))
    all_sentences = coerce_json_list(lesson_rows[0].get("sentences")) if lesson_rows else []

    new_entries: list[dict] = []
    for w in word_rows:
        text, gloss = sentence_for_word(w)
        sid = sentence_id_for(lang, text)
        entry = {"sentence_id": sid, "word": w["word"], "text": text, "gloss": gloss, "chosen": True}
        all_sentences.append(entry)
        new_entries.append(entry)
        await run_query(
            """INSERT INTO course_simple.sentence (sentence_id, lang, text, gloss)
            VALUES (%s, %s, %s, %s)
            ON CONFLICT (sentence_id) DO NOTHING""",
            (sid, lang, text, gloss),
        )

    await run_query(
        "UPDATE course_simple.lesson SET sentences = %s WHERE lesson_id = %s",
        (json.dumps(all_sentences), lesson_id),
    )
    return new_entries


@router.post("/generate_sentences", response_model=GenerateSentencesResponse)
async def generate_sentences(request: GenerateSentencesRequest, school_user: SchoolUser = Depends(current_ai_school_user)):
    """
    Draft example sentences for a lesson's already-selected words (the
    "Create sentences" path — as opposed to /generate_lesson, which skips
    straight to exercises).
    """
    lesson = await assert_lesson_owned(request.lesson_id, school_user)
    new_entries = await _generate_and_persist_sentences(lesson["course_id"], request.lesson_id)
    sentences = [LessonSentenceOut(**e) for e in new_entries]

    tokens, cost = mock_usage(len(sentences))
    message = f"Generated {len(sentences)} draft sentences for lesson {request.lesson_id}."
    return GenerateSentencesResponse(
        prompt_type=PromptType.CREATE_LESSON,
        prompt=message,
        response=message,
        course_id=lesson["course_id"],
        actual_tokens=tokens,
        actual_cost=cost,
        sentences=sentences,
    )


async def _generate_exercises_for_sentences(lesson_id: int, sentence_entries: list[dict]) -> list[ExerciseOut]:
    """Shared by /generate_exercises (chosen sentences already persisted)
    and /generate_lesson (build + generate in one shot). Each exercise
    keeps its own copy of the prompt text (`sentence`) plus the source
    sentence's id for reference only — editing one later never touches
    the other."""
    lesson_rows = await get_query_results(
        "SELECT course_id, module_id, words FROM course_simple.lesson WHERE lesson_id = %s", (lesson_id,)
    )
    course_id, module_id = lesson_rows[0]["course_id"], lesson_rows[0]["module_id"]
    word_pool = lesson_rows[0]["words"] or []

    exercises: list[ExerciseOut] = []
    for i, s in enumerate(sentence_entries):
        correct = s.get("word") or "?"
        options = generate_exercise_options(correct, word_pool, i)
        prompt = exercise_prompt_for_gloss(s.get("gloss"))
        rows = await get_query_results(
            """INSERT INTO course_simple.exercise (course_id, module_id, lesson_id, exercise_type, sentence, sentence_id, options, answer)
            VALUES (%s, %s, %s, 'single_choice', %s, %s, %s, %s)
            RETURNING exercise_id, lesson_id, sentence_id, exercise_type, sentence, options, answer""",
            (course_id, module_id, lesson_id, prompt, s["sentence_id"], json.dumps(options), correct),
        )
        exercises.append(exercise_from_row(rows[0]))

    await run_query("UPDATE course_simple.lesson SET status = 'ready' WHERE lesson_id = %s", (lesson_id,))
    return exercises


@router.post("/generate_exercises", response_model=GenerateExercisesResponse)
async def generate_exercises(request: GenerateExercisesRequest, school_user: SchoolUser = Depends(current_ai_school_user)):
    """
    Build exercises from a lesson's chosen (kept) sentences and mark the
    lesson ready. The "Create exercises" step after "Create sentences".
    """
    lesson = await assert_lesson_owned(request.lesson_id, school_user)
    all_sentences = await _lesson_sentences_jsonb(request.lesson_id)
    chosen = [s for s in all_sentences if s.get("chosen", True)]
    exercises = await _generate_exercises_for_sentences(request.lesson_id, chosen)

    tokens, cost = mock_usage(len(exercises))
    message = f"Generated {len(exercises)} exercises for lesson {request.lesson_id}."
    return GenerateExercisesResponse(
        prompt_type=PromptType.CREATE_LESSON,
        prompt=message,
        response=message,
        course_id=lesson["course_id"],
        actual_tokens=tokens,
        actual_cost=cost,
        exercises=exercises,
    )


async def _lesson_sentences_jsonb(lesson_id: int) -> list[dict]:
    rows = await get_query_results("SELECT sentences FROM course_simple.lesson WHERE lesson_id = %s", (lesson_id,))
    return coerce_json_list(rows[0].get("sentences")) if rows else []


@router.post("/generate_lesson", response_model=GenerateLessonResponse)
async def generate_lesson(request: GenerateLessonRequest, school_user: SchoolUser = Depends(current_ai_school_user)):
    """
    "Create exercises directly" — generate sentences AND exercises for a
    lesson's selected words in one call, skipping the confirm-sentences
    step.
    """
    if not request.lesson_id:
        raise HTTPException(status_code=400, detail="lesson_id is required")
    lesson = await assert_lesson_owned(request.lesson_id, school_user)
    new_entries = await _generate_and_persist_sentences(lesson["course_id"], request.lesson_id)
    sentences = [LessonSentenceOut(**e) for e in new_entries]

    exercises = await _generate_exercises_for_sentences(request.lesson_id, new_entries)

    tokens, cost = mock_usage(len(sentences) + len(exercises))
    title = request.title or "Lesson"
    message = f"Generated sentences and exercises for {title} in one go."
    return GenerateLessonResponse(
        prompt_type=PromptType.CREATE_LESSON,
        prompt=message,
        title=title,
        response=message,
        course_id=lesson["course_id"],
        actual_tokens=tokens,
        actual_cost=cost,
        sentences=sentences,
        exercises=exercises,
    )
