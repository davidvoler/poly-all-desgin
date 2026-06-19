from fastapi import APIRouter, Depends, HTTPException


router = APIRouter()

@router.get("/")
async def get_users():
    return []