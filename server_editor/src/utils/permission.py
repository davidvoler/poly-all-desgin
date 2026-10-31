


async def get_school_user() -> bool:
    return True

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


