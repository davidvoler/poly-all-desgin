from utils.db import get_query_results
from models.auth import SchoolUser

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


async def get_user_full_data(user_id: int, school ) -> SchoolUser:
    user_data = await _get_school_user(user_id, school.school_id)
    school_user =  SchoolUser(**user_data)
    school_user.school_name = school.name
    school_user.school_type = school.school_type
    school_user.logo_url = school.logo_url
    school_user.primary_color = school.primary_color
    school_user.school_id = school.school_id
    school_user.domain = school.domain
    school_user.dashboard = school.dashboard
    return school_user
