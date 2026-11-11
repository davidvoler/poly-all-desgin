from fastapi import APIRouter
from models.language import Language
from utils.lang_utils import get_top_languages
router = APIRouter()

@router.get("/top-languages", response_model=list[Language])
async def _get_top_languages(ui_language: str = 'en') -> list[Language]:
    return get_top_languages(ui_language)
