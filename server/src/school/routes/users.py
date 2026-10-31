from fastapi import APIRouter, Depends, HTTPException
from utils.db import get_query_results
from utils.auth_deps import current_school_user_full
from models.auth import SchoolUser


router = APIRouter()

@router.get("/")
async def get_users(school_user: dict = Depends(current_school_user_full)) -> list[dict]:
    if not school_user:
        raise HTTPException(status_code=401, detail="Not signed in")
    if school_user.status != "active":
        if "admin" in school_user.roles or "super_admin" in school_user.roles:
            sql = "SELECT * FROM school.school_users WHERE school_id = %s"
            params = (school_user.school_id,)
            results = await get_query_results(sql, params)
            return results
    else:
        raise HTTPException(status_code=403, detail="User is not active")