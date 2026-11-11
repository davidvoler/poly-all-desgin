from fastapi import APIRouter, Depends, HTTPException

from models.api_key import ApiKeyInfo, ApiKeySave, ApiKeyScope
from utils.api_keys import KEY_PROVIDERS, delete_key, list_keys, save_key
from utils.permission import SchoolUser, can_manage_school_keys, get_school_user
from utils.secret_box import SecretBoxError

router = APIRouter()


async def _check(scope: ApiKeyScope, provider: str, school_user: SchoolUser):
    if provider not in KEY_PROVIDERS:
        raise HTTPException(status_code=400, detail=f"Unknown provider: {provider}")
    if scope == ApiKeyScope.SCHOOL and not await can_manage_school_keys(school_user):
        raise HTTPException(status_code=403, detail="Only school admins can change the school's keys")


@router.get("/keys", response_model=list[ApiKeyInfo])
async def _list_keys(school_user=Depends(get_school_user)) -> list[ApiKeyInfo]:
    """The school's keys and the user's own. Only the last 4 characters are shown."""
    return await list_keys(school_user.school, school_user.user_id)


@router.put("/keys", response_model=ApiKeyInfo)
async def _save_key(body: ApiKeySave, school_user=Depends(get_school_user)) -> ApiKeyInfo:
    """Adds or replaces a key. A school key is shared by the school's users."""
    await _check(body.scope, body.provider, school_user)
    try:
        return await save_key(school_user.school, school_user.user_id, body.scope,
                              body.provider, body.api_key.get_secret_value())
    except SecretBoxError as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/keys")
async def _delete_key(provider: str, scope: ApiKeyScope,
                      school_user=Depends(get_school_user)) -> dict:
    await _check(scope, provider, school_user)
    if not await delete_key(school_user.school, school_user.user_id, scope, provider):
        raise HTTPException(status_code=404, detail="No such key")
    return {"status": "success"}
