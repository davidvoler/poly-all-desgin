from fastapi import APIRouter, File, HTTPException, UploadFile
from editor.models import LessonData

router = APIRouter()


@router.post("/")
async def add_lesson_to_course(data: LessonData):
    
    pass 
