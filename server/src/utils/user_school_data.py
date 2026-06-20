from utils.db import get_query_results
from models.auth import SchoolUser

# Latest editor Terms & Conditions version. Bump when legal/EDITOR_TERMS.txt
# is revised so already-signed users are re-prompted. Mirrors the default on
# the school.terms table and POST /api/v1/school/sign_editor_terms.
LATEST_TERMS_VERSION = 1

# Roles that unlock admin-only surfaces (Settings, Editors). Spans the new
# (school_admin / super_admin) and legacy (admin / owner) vocabularies so a
# user seeded with either keeps working — mirrors the client's _adminRoles.
_ADMIN_ROLES = {"admin", "owner", "school_admin", "super_admin"}
# Roles that may manage course content.
_COURSE_ROLES = _ADMIN_ROLES | {"editor", "super_editor"}


def _get_latest_terms_version() -> int:
    return LATEST_TERMS_VERSION


def _get_user_dashboard_permission(user: dict, school_payment_status: bool) -> dict:
    status = user.get("status", 'inactive')
    roles = user.get("roles") or []
    # signed_terms_version is NULL for users who've never signed — treat as 0.
    signed_terms_version = user.get("signed_terms_version") or 0
    permissions = {
        "about": True,
        "settings": False,
        "editors": False,
        "courses": False,
        "create_with_ai": False,
        "signed_terms": False,
    }
    if status != "active":
        return permissions
    # signed_terms=True means the user still owes us an acceptance of the
    # current version — the dashboard gates the Courses page on it.
    if signed_terms_version < _get_latest_terms_version():
        permissions["signed_terms"] = True
    if any(r in _ADMIN_ROLES for r in roles):
        permissions["settings"] = True
        permissions["editors"] = True
        permissions["courses"] = True
    if any(r in _COURSE_ROLES for r in roles):
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
    # Compute the dashboard capabilities once here so every consumer
    # (the /me endpoint, the courses guard, …) reads the same decision.
    # Payment status is hard-coded True until billing gating lands.
    school_user.permissions = _get_user_dashboard_permission(
        user_data, school_payment_status=True)
    return school_user
