from fastapi import APIRouter, Depends
from school.models import User
router = APIRouter()


@router.get("/")
async def get_users(school_id: int):
    return {}

@router.post("/create_user")
async def create_user(user: User):
    return {}

@router.post("/create_user")
async def create_user(user: User):
    return {}
