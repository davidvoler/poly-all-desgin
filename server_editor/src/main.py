from fastapi import FastAPI

app = FastAPI()

from routers import (
    course, exercise, generate, lesson, module, video
)



app.include_router(course.router, prefix="/api/v1/courses", tags=["courses"])
app.include_router(exercise.router, prefix="/api/v1/exercises", tags=["exercises"])
app.include_router(generate.router, prefix="/api/v1/generate", tags=["generate"])
app.include_router(lesson.router, prefix="/api/v1/lessons", tags=["lessons"])
app.include_router(module.router, prefix="/api/v1/modules", tags=["modules"])
app.include_router(video.router, prefix="/api/v1/video", tags=["video"])
