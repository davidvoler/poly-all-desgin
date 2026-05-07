from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from routers import (
    lesson,
    course,
    user_data
)

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["POST", "GET", "OPTIONS", "PUT", "DELETE", "PATCH"],
    allow_headers=["*"],
)

app.include_router(course.router,
    prefix="/api/v1/course",
    tags=["course"])
app.include_router(user_data.router,
    prefix="/api/v1/user_data",
    tags=["user_data"])
app.include_router(lesson.router,
    prefix="/api/v1/lesson",
    tags=["lesson"])
