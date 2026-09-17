from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from utils.auth_deps import current_school_user
from models.auth import SchoolUser
from models.edit.youtube import YoutubeInfo, SubtitleInfo, SubtitlesDownloadRequest
from utils.edit.youtube_srt import  youtube_subs

router = APIRouter()


@router.get("/info/{video_id}/{lang}", response_model=YoutubeInfo)
async def import_course(video_id: str, 
                        lang: str,
                        school_user: SchoolUser  = Depends(current_school_user)):
    #TODO: Implement logic to fetch YouTube video info and subtitles
    subs = youtube_subs(video_id, lang )
    return YoutubeInfo(video_id=video_id, title="Sample Video", subtitles_langs=["en", "es"], lang="en")



@router.post("/download_subtitle/", response_model=SubtitleInfo)
async def import_course(download_request: SubtitlesDownloadRequest, school_user: SchoolUser  = Depends(current_school_user)):
    # TODO: Implement logic to download subtitles and create a course import
    subs, video_seconds = youtube_subs(download_request.video_id, download_request.lang)
    return SubtitleInfo(video_id=download_request.video_id, 
                        title="Sample Video",
                        video_lang=download_request.lang, 
                        lines=subs, 
                        sentences=[], 
                        words=[])    
