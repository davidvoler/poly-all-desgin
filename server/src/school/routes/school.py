from fastapi import APIRouter, Depends
from school.models.school import School
router = APIRouter()


@router.get("/")
async def get_schools():
    return {}

@router.post("/")
async def create_school(school: School):
    return {}
