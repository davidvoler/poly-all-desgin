from fastapi import APIRouter, Depends

router = APIRouter()


@router.get("/")
async def get_user_data(user_id: int | None = None):
    # Placeholder for fetching courses from the database
    return {}
