from models.edit.generate_poc import *
from models.edit.course import Course
from models.auth import  SchoolUser
from fastapi import APIRouter, Depends
from server.src.utils.auth_deps import current_school_user

router = APIRouter()


async def create_course():
    # Implement the logic for creating a course here
    return PromptResponse()


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
def generate_course(request: GenerateCourseRequest, school_user: SchoolUser = Depends(current_school_user)):
    """
    Generate a new course based on the provided request.
    """
    if not request.title:
        # Handle missing title
        request.title = "Untitled Course"
    if not request.description:
        # Handle missing description
        request.description = "No description provided."
    
    return PromptResponse()


@router.post("/generate_lesson", response_model=PromptResponse)
def generate_lesson(request: GenerateLessonRequest):
    # Implement the logic for generating lesson here
    return PromptResponse()


@router.post("/generate_words_list", response_model=PromptResponse)
def generate_words_list(request: GenerateCourseWordsListRequest):
    # Implement the logic for generating words list here
    return PromptResponse()