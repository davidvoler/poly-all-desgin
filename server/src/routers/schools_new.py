from fastapi import APIRouter, Depends
from utils.auth_deps import current_school_user_full, current_user_id
from utils.db import get_query_results


router = APIRouter()

def _get_latest_terms_version() -> int:
    return 1

def _get_user_dashboard_permission(user:dict, school_payment_status: bool) -> dict:
    status = user.get("status", 'inactive')
    roles = user.get("roles", [])
    signed_terms_version = user.get("signed_terms_version", 0)
    permissions = {
        "about": True,
        "settings": False,
        "courses": False,
        "create_with_ai": False,
    }
    if status != "active":
        return permissions
    if signed_terms_version < _get_latest_terms_version():
        permissions["signed_terms"] = True
    if "admin" in roles:
        permissions["settings"] = True
        permissions["courses"] = True
    if "editor" in roles:
        permissions["courses"] = True
    if "ai_creator" in roles and school_payment_status:
        permissions["create_with_ai"] = True
    return permissions    

async def _get_school_user(user_id: int, school_id: int) -> dict:
    sql = "SELECT * FROM school.school_users WHERE user_id = %s AND school_id = %s"
    params = (user_id, school_id)
    results = await get_query_results(sql, params)
    return results[0] if results else {}

@router.get("/dashboard")
async def get_dashboard(user_id: int = Depends(current_user_id)):
    user_id, school_id = get_user_id_school_id(user_id)
    school_user_data = await _get_school_user(user_id, school_id)
    permissions = _get_user_dashboard_permission(school_user_data, school_payment_status=True)  # Placeholder for actual payment status
    return {
        "permissions": permissions,
        "user_id": user_id,
        "school_id": school_id,
    }

