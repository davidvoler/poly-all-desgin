from fastapi import HTTPException, Depends, APIRouter
from models.video import Subtitle
from utils.db import get_query_results
from utils.permission import get_school_user
router = APIRouter()



@router.get("/get_subtitles", response_model=list[Subtitle])
async def get_subtitles(lang: str, to_lang: str, school_user=Depends(get_school_user)):
    pass 

@router.get("/video_sections", response_model=list[Subtitle])
async def get_video_sections(lang: str, to_lang: str, school_user=Depends(get_school_user)):
    pass 

@router.get("/elements", response_model=list[Subtitle])
async def get_video_sections(lang: str, to_lang: str, school_user=Depends(get_school_user)):
    pass 

