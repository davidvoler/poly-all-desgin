import json
from pathlib import Path

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from utils.auth_deps import current_school_user, current_school_user_full
from utils.db import get_query_results, run_query
from utils.jsonb import coerce_json_list
from models.auth import SchoolUser
from models.edit.course import Course, CourseImport
from models.edit.ai_course import CourseFull, CourseWord, LessonOut, ModuleFull
from models.edit.ai_course import exercise_from_row, LessonSentenceOut
TEMP_FOLDER = "../content/temp"

router = APIRouter()

def _row_to_course(row: dict) -> Course:
    return Course(**{**row, "published": row.get("status") == "published"})

@router.get("/courses", response_model=list[Course])
async def get_courses(school_user: SchoolUser  = Depends(current_school_user_full)):
    # depending on user permissions we may be able to see more courses.
    # user_id is a varchar column (legacy) — cast the param so it can be
    # compared against an int SchoolUser.user_id.
    sql = """SELECT *
    FROM course_simple.course
    WHERE user_id = %s::text and school_id = %s
    ORDER BY updated_at desc"""
    results = await get_query_results(sql, (school_user.user_id, school_user.school_id))
    if not results:
        return []

    # "My courses" (create_with_ai_poc) shows word/module/lesson counts per
    # course — module/lesson counts are cheap grouped counts; word count is
    # just the length of the course's own words jsonb list.
    course_ids = [r["course_id"] for r in results]
    module_rows = await get_query_results(
        "SELECT course_id, count(*) AS n FROM course_simple.module WHERE course_id = ANY(%s) GROUP BY course_id",
        (course_ids,),
    )
    lesson_rows = await get_query_results(
        """SELECT course_id, count(*) AS n, count(*) FILTER (WHERE status = 'ready') AS ready
        FROM course_simple.lesson WHERE course_id = ANY(%s) GROUP BY course_id""",
        (course_ids,),
    )
    module_counts = {r["course_id"]: r["n"] for r in module_rows}
    lesson_counts = {r["course_id"]: r for r in lesson_rows}

    courses = []
    for row in results:
        course = _row_to_course(row)
        cid = row["course_id"]
        course.word_count = len(coerce_json_list(row.get("words")))
        course.module_count = module_counts.get(cid, 0)
        lrow = lesson_counts.get(cid, {})
        course.lesson_count = lrow.get("n", 0)
        course.ready_lesson_count = lrow.get("ready", 0)
        courses.append(course)
    return courses

@router.get("/course/{course_id}", response_model=Course)
async def get_course(course_id:int, school_user: SchoolUser  = Depends(current_school_user)):
    #select course with the a list of modules
    sql = "SELECT * FROM course_simple.course WHERE course_id = %s and user_id = %s::text and school_id = %s"
    results = await get_query_results(sql, (course_id, school_user.user_id, school_user.school_id))
    return _row_to_course(results[0]) if results else None

@router.get("/course/{course_id}/full", response_model=CourseFull)
async def get_course_full(course_id: int, school_user: SchoolUser = Depends(current_school_user)):
    """Everything the create_with_ai_poc course workspace needs in one
    call: course meta, the word list (with used-in-a-lesson flags), and
    every module/lesson/sentence/exercise. Backs the Words/Lessons/Edit
    Course/Preview tabs without N+1 round-trips."""
    course_rows = await get_query_results(
        "SELECT * FROM course_simple.course WHERE course_id = %s AND user_id = %s::text AND school_id = %s",
        (course_id, school_user.user_id, school_user.school_id),
    )
    if not course_rows:
        raise HTTPException(status_code=404, detail="Course not found")
    course = course_rows[0]

    module_rows = await get_query_results(
        "SELECT module_id, title FROM course_simple.module WHERE course_id = %s ORDER BY weight, module_id",
        (course_id,),
    )
    lesson_rows = await get_query_results(
        "SELECT lesson_id, module_id, course_id, title, status, words, sentences FROM course_simple.lesson WHERE course_id = %s ORDER BY weight, lesson_id",
        (course_id,),
    )
    lesson_ids = [l["lesson_id"] for l in lesson_rows]

    # Word "used" tracking: a word is used once it appears in any lesson's
    # `words` array (course_simple.lesson.words text[] — no join table).
    used_words: set[str] = set()
    for l in lesson_rows:
        used_words.update(l.get("words") or [])

    course_words = coerce_json_list(course.get("words"))
    # `used` is recomputed here from lesson membership, so drop any stored
    # `used` key (the generate_poc_new word list persists CourseWord with
    # its own word/weight/used shape) to avoid a duplicate-kwarg clash.
    words = [
        CourseWord(**{k: v for k, v in w.items() if k != "used"}, used=w["word"] in used_words)
        for w in course_words
    ]

    exercises_by_lesson: dict[int, list] = {}
    if lesson_ids:
        exercise_rows = await get_query_results(
            """SELECT exercise_id, lesson_id, sentence_id, exercise_type, sentence, options, answer
            FROM course_simple.exercise WHERE lesson_id = ANY(%s) ORDER BY exercise_id""",
            (lesson_ids,),
        )
        for r in exercise_rows:
            exercises_by_lesson.setdefault(r["lesson_id"], []).append(exercise_from_row(r))

    lessons_by_module: dict[int, list[LessonOut]] = {}
    for l in lesson_rows:
        lid = l["lesson_id"]
        lessons_by_module.setdefault(l["module_id"], []).append(LessonOut(
            lesson_id=lid,
            module_id=l["module_id"],
            course_id=l["course_id"],
            title=l["title"],
            status=l["status"],
            words=l.get("words") or [],
            sentences=[LessonSentenceOut(**s) for s in coerce_json_list(l.get("sentences"))],
            exercises=exercises_by_lesson.get(lid, []),
        ))

    modules = [
        ModuleFull(module_id=m["module_id"], title=m["title"], lessons=lessons_by_module.get(m["module_id"], []))
        for m in module_rows
    ]

    return CourseFull(
        course_id=course["course_id"],
        title=course["title"],
        description=course.get("description") or "",
        lang=course["lang"],
        to_lang=course["to_lang"],
        level=course.get("level") or "",
        words=words,
        modules=modules,
    )

@router.post("/course", response_model=Course)
async def create_course(course: Course, school_user: SchoolUser  = Depends(current_school_user)):
    #insert a new course
    sql = """UPDATE course_simple.course
    SET title = %s, description = %s, lang = %s, to_lang = %s, metadata = %s, status = %s, level = %s
    WHERE course_id = %s
    AND user_id = %s::text AND school_id = %s
    """
    values = (course.title, course.description, course.lang,
              course.to_lang, json.dumps(course.metadata),
              "published" if course.published else "draft",
              course.level or '',
              course.course_id, school_user.user_id, school_user.school_id)
    try:
        results = await get_query_results(sql, values)
    except Exception as e:
        print(f"Error creating course: {e}")
        return None
    return course

@router.delete("/course/{course_id}")
async def delete_course(course_id: int, school_user: SchoolUser = Depends(current_school_user)):
    """Delete a course and everything under it — modules, lessons and
    exercises (lesson.sentences is inline jsonb, so it goes with the
    lesson row). There are no FK cascades in course_simple, so this walks
    the tables child-first. course_simple.sentence is a content-addressable
    cache shared across courses, so it's left alone."""
    owned = await get_query_results(
        "SELECT course_id FROM course_simple.course WHERE course_id = %s AND user_id = %s::text AND school_id = %s",
        (course_id, school_user.user_id, school_user.school_id),
    )
    if not owned:
        raise HTTPException(status_code=404, detail="Course not found")

    try:
        for table in ("exercise", "lesson", "module"):
            await run_query(
                f"DELETE FROM course_simple.{table} WHERE course_id = %s", (course_id,)
            )
        await run_query(
            "DELETE FROM course_simple.course WHERE course_id = %s AND user_id = %s::text AND school_id = %s",
            (course_id, school_user.user_id, school_user.school_id),
        )
    except Exception as e:
        print(f"Error deleting course {course_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    return {"success": True, "message": f"Course {course_id} deleted"}
