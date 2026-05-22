from fastapi import APIRouter, Depends
router = APIRouter()


@router.post("/")
async def upload_course(lesson_id: int):
    return {}