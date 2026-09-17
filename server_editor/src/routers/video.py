from fastapi import HTTPException, Depends, APIRouter
from models.video import Subtitle
from utils.db import get_query_results
from utils.permission import get_school_user
from utils.subtitle import break_subtitles_into_sections
router = APIRouter()



@router.get("/get_subtitles", response_model=list[Subtitle])
async def get_subtitles(lang: str, to_lang: str, school_user=Depends(get_school_user)):
    pass 

@router.get("/video_sections", response_model=list[Subtitle])
async def get_video_sections(lang: str, to_lang: str, section_length_seconds: int=120,  school_user=Depends(get_school_user)):
    subtitles = []  # Replace this with the actual logic to fetch subtitles
    return break_subtitles_into_sections(subtitles, break_video_seconds=section_length_seconds)

@router.get("/elements", response_model=list[Subtitle])
async def get_video_sections(lang: str, to_lang: str, school_user=Depends(get_school_user)):
    pass 

