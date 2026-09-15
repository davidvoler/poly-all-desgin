from fastapi import APIRouter, HTTPException, Depends
from tasks.generate_quiz import generate_words_with_ai, generate_quiz_with_ai
from models.generate import GenerateLessonRequest, GenerateQuizRequest
from models.tasks import TaskStatus
from utils.db import  get_query_results
from utils.permission import has_course_permission
router = APIRouter()

@router.post("/generate_words")
async def generate_words(request: GenerateWordsRequest, has_permission=Depends(has_course_permission)):
    if not has_permission:
        raise HTTPException(status_code=403, detail="Permission denied")
    task = await generate_words_with_ai(request.course_id, request.module_id, request.count, request.word, request.school_user)
    return TaskStatus(
            task_id=task.task_id,
            task_type="generate_words",
            status="pending",
    )

@router.post("/generate_quiz")
async def generate_quiz(request: GenerateQuizRequest, has_permission=Depends(has_course_permission)):
    if not has_permission:
        raise HTTPException(status_code=403, detail="Permission denied")
    task = await generate_quiz_with_ai(request.course_id, request.module_id, request.count, request.word, request.school_user)
    return TaskStatus(
            task_id=task.task_id,
            task_type="generate_quiz",
            status="pending",
    )   


@router.post("/generate_lesson")
async def generate_lesson(request: GenerateLessonRequest, has_permission=Depends(has_course_permission))->list[TaskStatus]:
    if not has_permission:
        raise HTTPException(status_code=403, detail="Permission denied")
    sql ="""INSERT INTO course.lesson (course_id, module_id, words, lang, to_lang) 
              VALUES (%s, %s, %s, %s, %s)
              RETURNING lesson_id
        """
    values = (request.course_id, request.module_id, request.words, request.lang, request.to_lang)
    lesson_id = await get_query_results(sql, values)
    results = []
    for word in request.words:
        task = await generate_quiz_with_ai(request.course_id, request.module_id, request.words, request.lang, request.to_lang)
        results.append(TaskStatus(
                task_id=task.task_id,
                task_type="generate_quiz",
                status="pending",
        ))
    return results
    