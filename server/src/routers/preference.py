from fastapi import APIRouter, Depends
from utils.db import get_query_results
from models.preference import Preference
router = APIRouter()


@router.get("/")
async def get_user_preferences(user_id: int | None = None):
    if user_id is None:
        user_id = 1 # default user for development
    query = "SELECT * FROM user_data.preference WHERE user_id = %s"
    results = await get_query_results(query, (user_id,))
    for r in results:
        return Preference(**r)
    return None

@router.post("/")
async def update_user_preferences(preferences: Preference):
    query = """
    UPDATE user_data.preference
    SET course_id = %s, module_id = %s, lesson_id = %s,
        ui_lang = %s, lang = %s, to_lang = %s
    WHERE user_id = %s
    """
    params = (
        preferences.course_id,
        preferences.module_id,
        preferences.lesson_id,
        preferences.ui_lang,
        preferences.lang,
        preferences.to_lang,
        preferences.user_id
    )
    await get_query_results(query, params)
    return preferences