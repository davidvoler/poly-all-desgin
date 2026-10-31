from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from models import word
from task_runner import lifespan
app = FastAPI(lifespan=lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

from routers import (
    course, exercise,
    lesson, module, video, 
    prompt, task_status,
    context, languages, words,
)



app.include_router(course.router, prefix="/api/v1/courses", tags=["courses"])
app.include_router(exercise.router, prefix="/api/v1/exercises", tags=["exercises"])
app.include_router(lesson.router, prefix="/api/v1/lessons", tags=["lessons"])
app.include_router(module.router, prefix="/api/v1/modules", tags=["modules"])
app.include_router(video.router, prefix="/api/v1/video", tags=["video"])
app.include_router(prompt.router, prefix="/api/v1/prompt", tags=["prompt"])
app.include_router(task_status.router, prefix="/api/v1/tasks", tags=["tasks"])
app.include_router(context.router, prefix="/api/v1/context", tags=["context"])
app.include_router(languages.router, prefix="/api/v1/language", tags=["language"])
app.include_router(words.router, prefix="/api/v1/words", tags=["words"])
