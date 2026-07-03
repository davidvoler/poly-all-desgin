from utils.db import get_query_results
from models.auth import SchoolUser
from models.edit.permission import CoursePermission

async def get_course_permission(course_id: int, school_user: SchoolUser)-> CoursePermission:
    """return user permission for a given course_id"""
    return CoursePermission(course_id=course_id, user_id=school_user.user_id, school_id=school_user.school_id)