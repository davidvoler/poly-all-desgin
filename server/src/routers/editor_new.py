from fastapi import APIRouter, Depends
from utils.auth_deps import current_school_user_full, current_user_id
from utils.db import get_query_results

router = APIRouter()


async def _get_user_courses(user_id: int) -> list[int]:
    return []
@router.get("/courses")
async def get_dashboard(user_id: int = Depends(current_user_id)):