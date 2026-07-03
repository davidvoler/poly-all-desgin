from fastapi import APIRouter, Depends
from utils.auth_deps import current_school_user, current_school_user_full
from utils.db import get_query_results
from models.auth import SchoolUser
from models.edit.course import Course, Revision


router = APIRouter()


@router.get("/courses", response_model=list[Course])
async def get_courses(school_user: SchoolUser  = Depends(current_school_user_full)):
    # depending on user permissions we may be able to see more courses
    sql = "SELECT * FROM course_simple.course WHERE user_id = %s and school_id = %s order by last_updated desc"
    results = await get_query_results(sql, (school_user.user_id, school_user.school_id))
    return [Course(**course) for course in results] if results else []


@router.get("/revisions/{course_id}", response_model=list[Revision])
# depending on user permissions we may be able to see more revisions
async def get_revisions(course_id:int,school_user: SchoolUser  = Depends(current_school_user_full)):
    sql = "SELECT * FROM course_simple.revision WHERE user_id = %s and school_id = %s order by last_updated desc"
    results = await get_query_results(sql, (school_user.user_id, school_user.school_id))
    return [Revision(**course) for course in results] if results else []

@router.get("/course/{course_id}", response_model=CourseEdit)
async def get_course(course_id:int, school_user: SchoolUser  = Depends(current_school_user)):
    #select course with the a list of modules
    sql = "SELECT * FROM course_simple.course WHERE course_id = %s and user_id = %s and school_id = %s"
    results = await get_query_results(sql, (course_id, school_user.user_id, school_user.school_id))
    return Course(**results[0]) if results else None

@router.post("/revision", response_model=Revision)
async def update_revision(revision: Revision, school_user: SchoolUser  = Depends(current_school_user_full)):
    pass 

@router.post("/revision", response_model=Revision)
async def update_revision(revision: Revision, school_user: SchoolUser  = Depends(current_school_user_full)):
    pass 