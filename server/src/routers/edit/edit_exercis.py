from fastapi import APIRouter, Depends
from utils.auth_deps import current_school_user, current_school_user_full
from utils.db import get_query_results
from models.auth import SchoolUser
from models.edit.exercise import Exercise, ExerciseRequest


router = APIRouter()


@router.get("/", response_model=list[Exercise])
async def get_courses(exercise_request: ExerciseRequest, school_user: SchoolUser  = Depends(current_school_user_full)):
    # get a list of exercise for a given course, module, lesson
    # TODO: verify users has access to this course
    pass 


@router.post("/", response_model=Exercise)
async def update_revision(revision: Revision, school_user: SchoolUser  = Depends(current_school_user_full)):
    pass 

@router.post("/revision", response_model=Revision)
async def update_revision(revision: Revision, school_user: SchoolUser  = Depends(current_school_user_full)):
    pass 