from fastapi import APIRouter, Depends
from utils.auth_deps import current_user_id
from utils.db import get_query_results, run_query
from models.preference import Preference
router = APIRouter()


@router.get("/")
async def get_user_preferences(user_id: int = Depends(current_user_id)):
    query = "SELECT * FROM user_data.preference WHERE user_id = %s"
    results = await get_query_results(query, (user_id,))
    for r in results:
        return Preference(**r)
    return None

@router.post("/")
async def update_user_preferences(preferences: Preference,
                                  user_id: int = Depends(current_user_id)):
    # Trust the cookie, not the body — clients shouldn't be able to
    # write another user's preference row by tampering with user_id.
    query = """
    INSERT into user_data.preference (user_id, course_id, module_id, lesson_id, ui_lang, lang, to_lang, course_name, module_name, lesson_name)
    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
    on conflict (user_id, lang) do update
    SET course_id = %s, module_id = %s, lesson_id = %s,
        ui_lang = %s, lang = %s, to_lang = %s, course_name = %s, module_name = %s, lesson_name = %s
    WHERE  user_data.preference.user_id = %s AND user_data.preference.lang = %s
    """
    params = (
        user_id,
        preferences.course_id,
        preferences.module_id,
        preferences.lesson_id,
        preferences.ui_lang,
        preferences.lang,
        preferences.to_lang,
        preferences.course_name,
        preferences.module_name,
        preferences.lesson_name,
        preferences.course_id,
        preferences.module_id,
        preferences.lesson_id,
        preferences.ui_lang,
        preferences.lang,
        preferences.to_lang,
        preferences.course_name,
        preferences.module_name,
        preferences.lesson_name,
        user_id,
        preferences.lang
    )
    await run_query(query, params)
    return preferences
