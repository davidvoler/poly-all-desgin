


from pydantic import BaseModel


class SchoolUser(BaseModel):
    user_id: int
    school: str


# Placeholder identity until Auth0 is wired in.
LOCAL_SCHOOL_USER = SchoolUser(user_id=1, school="local")


async def get_school_user() -> SchoolUser:
    return LOCAL_SCHOOL_USER

async def has_course_permission(course_id, permission):
    """
    Check if the user has the specified edit permission for the given course.

    Args:
        course_id: The ID of the course.
        permission: The permission to check. edit,delete
    Returns:
        bool: True if the user has the permission, False otherwise.
    """
    school_user = await get_school_user()
    # Implement your permission logic here
    return True


