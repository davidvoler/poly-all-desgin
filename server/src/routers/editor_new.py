from fastapi import APIRouter, Depends
from utils.auth_deps import current_user_id_school_id, get_user_roles
from utils.auth_deps import current_user_id, get_user_id_school_id
from utils.db import get_query_results

router = APIRouter()


async def _get_user_courses(user_id: int) -> list[int]:
    return []
@router.get("/courses")
async def get_dashboard(user_id: int = Depends(current_user_id)):