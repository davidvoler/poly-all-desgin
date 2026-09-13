from fastapi import APIRouter, HTTPException, Depends

from server.src.models.edit.generate_poc import GenerateWordsRequest


router = APIRouter()

@router.post("/generate_words")
async def generate_words(request: GenerateWordsRequest):
    pass

@router.post("/generate_quiz")
async def generate_quiz(request: GenerateQuizRequest):
    pass