from models.edit.generate_poc import *
from fastapi import APIRouter, Depends

router = APIRouter()


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


