from fastapi import HTTPException, Depends, APIRouter
from models.video import Video
from utils.db import get_query_results
from utils.permission import get_school_user
router = APIRouter()



@router.get("/videos", response_model=list[Video])
async def list_videos(lang: str, to_lang: str, school_user=Depends(get_school_user)):
    query = """SELECT * FROM video.video 
    WHERE lang = %s AND to_lang = %s 
    AND deleted = false 
    AND user = %s
    AND school = %s""" 
    results = await get_query_results(query, (lang, to_lang, school_user.user_id, school_user.school))
    res = [Video(**row) for row in results]
    return res

@router.get("/video", response_model=Video)
async def get_video(video_id: int, lang: str, to_lang: str, school_user=Depends(get_school_user)):
    query = """SELECT * FROM video.video 
        WHERE lang = %s AND to_lang = %s 
        AND deleted = false 
        AND user = %s
        AND school = %s
        AND video_id = %s
        """ 
    results = await get_query_results(query, (lang, to_lang, school_user.user_id, school_user.school, video_id))
    if not results:
        raise HTTPException(status_code=404, detail="Video not found")
    res = [Video(**row) for row in results]
    return res[0]

@router.post("/get_subtitle", response_model=str)
async def get_subtitle(video_id: int, lang: str, to_lang: str, school_user=Depends(get_school_user)):
    query = """SELECT subtitle FROM video.video 
        WHERE lang = %s AND to_lang = %s 
        AND deleted = false 
        AND user = %s
        AND school = %s
        AND video_id = %s
        """ 
    results = await get_query_results(query, (lang, to_lang, school_user.user_id, school_user.school, video_id))
    if not results:
        raise HTTPException(status_code=404, detail="Subtitle not found")
    return results[0]["subtitle"]