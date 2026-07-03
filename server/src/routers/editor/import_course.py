from fastapi import APIRouter, Depends
from server.src.models.edit.course_edit import RevisionEdit
from utils.auth_deps import  current_school_user_full
from utils.db import get_query_results
from models.edit.import_course import ImportCourseRequest, ImportRevisionRequest
from models.edit.permission import CoursePermission
from utils.edit.edit_utils import get_course_permission
from models.auth import SchoolUser
router = APIRouter()

@router.post("/import_course")
async def import_course(
    import_course_request: ImportCourseRequest, 
    school_user: SchoolUser  = Depends(current_school_user_full)
):
    course_permision = await get_course_permission(import_course_request.course_id, school_user) 

@router.post("/import_revision")
async def import_revision(import_revision_request: ImportRevisionRequest, school_user: SchoolUser  = Depends(current_school_user_full)):
    course_permision = await get_course_permission(import_revision_request.course_id, school_user) 

