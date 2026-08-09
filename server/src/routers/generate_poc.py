
from models.edit.course import Course
from models.auth import  SchoolUser
from fastapi import APIRouter, Depends
from utils.auth_deps import current_school_user
from utils.db import get_query_results
from models.edit.generate_poc import (
    Prompt,
    PromptResponse,
    PromptResponseOption,
    GenerateCourseRequest,
    GenerateLessonRequest,
    GenerateCourseWordsListRequest,
    PromptType 
)
router = APIRouter()


async def create_course(lang, to_lang, user_id, school_id, title, description) -> int:
    # Implement the logic for creating a course here
    sql = f"""INSERT INTO course_simple.course (lang, to_lang, user_id, school_id, title, description, status) 
    VALUES (%s, %s, %s, %s, %s, %s, %s)
    RETURNING id"""
    params = (lang, to_lang, user_id, school_id, title, description, 'draft')
    result = await get_query_results(sql, params)
    return result[0]['id'] if result else 0


def create_title(lang: str | None, to_lang: str | None, user: str | None) -> str:
    return f"Course {lang or 'Unknown'} {to_lang or 'Unknown'} by {user or 'Unknown'}"

@router.post("/", response_model=PromptResponse)
def generate_poc(request: Prompt):
    # Implement the logic for generating POC here
    if request.prompt_type == PromptType.CREATE_COURSE:
        # Logic for creating a course
        pass
    elif request.prompt_type == PromptType.CREATE_LESSON:
        # Logic for creating a lesson
        pass
    elif request.prompt_type == PromptType.GET_WORDS:
        # Logic for getting words
        pass
    return PromptResponse()


@router.post("/generate_course", response_model=PromptResponse)
async def generate_course(request: GenerateCourseRequest, school_user: SchoolUser = Depends(current_school_user)):
    """
    Generate a new course based on the provided request.
    """
    if not request.title:
        request.title = create_title(request.lang, request.to_lang, school_user.username)
    if not request.description:
        # Handle missing description
        request.description = "No description provided."
    course_id = await create_course(
        request.lang,
        request.to_lang,
        school_user.user_id,
        school_user.school_id,
        request.title,
        request.description
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


@router.post("/generate_lesson", response_model=PromptResponse)
async def generate_lesson(request: GenerateLessonRequest, school_user: SchoolUser = Depends(current_school_user)):
    """
    Generate a new lesson for an existing course. POC stub: no AI call or DB
    write yet, just echoes back a result so the front end has something to
    show for the "Create Lesson" option.
    """
    title = request.title or "Greetings"
    return PromptResponse(
        prompt_type=PromptType.CREATE_LESSON,
        prompt=f"Lesson '{title}' generated for course {request.course_id}.",
        title=title,
        response=f"Lesson '{title}' generated for course {request.course_id}.",
        course_id=request.course_id,
        lang=request.lang,
        to_lang=request.to_lang,
    )


@router.post("/generate_words_list", response_model=PromptResponse)
async def generate_words_list(request: GenerateCourseWordsListRequest, school_user: SchoolUser = Depends(current_school_user)):
    """
    Generate a starter word list for a course. POC stub: no AI call or DB
    write yet, just echoes back a result so the front end has something to
    show for the "Get Words List" option.
    """
    return PromptResponse(
        prompt_type=PromptType.GET_WORDS,
        prompt=f"Word list generated for course {request.course_id}.",
        response=f"Word list generated for course {request.course_id}.",
        course_id=request.course_id,
    )