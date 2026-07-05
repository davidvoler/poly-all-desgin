from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from server.src.models.edit.course import CourseImport
from server.src.routers.edit import course_import
from utils.auth_deps import current_school_user, current_school_user_full
from utils.db import get_query_results
from models.auth import SchoolUser
from models.edit.youtube import YoutubeInfo, SubtitleInfo, SubtitlesDownloadRequest


router = APIRouter()


@router.get("/info/{video_id}", response_model=YoutubeInfo)
async def import_course(video_id: str, 
                        school_user: SchoolUser  = Depends(current_school_user)):
    #TODO: Implement logic to fetch YouTube video info and subtitles
    return YoutubeInfo(video_id=video_id, title="Sample Video", subtitles_langs=["en", "es"], lang="en")


@router.post("/download_subtitle/", response_model=SubtitleInfo)
async def import_course(download_request: SubtitlesDownloadRequest, school_user: SchoolUser  = Depends(current_school_user)):
    # TODO: Implement logic to download subtitles and create a course import
    return SubtitleInfo(video_id=download_request.video_id, title="Sample Video", video_lang="en", lines=[], sentences=[], words=[])    
