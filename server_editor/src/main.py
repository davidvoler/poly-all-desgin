from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from models import word
from task_runner import lifespan
import os

from fastapi import Depends
from utils.permission import get_school_user

app = FastAPI(lifespan=lifespan)
# Only the editor sites may call the API with the session cookie. The default
# allows localhost on any port; set EDITOR_ALLOWED_ORIGINS in production, e.g.
# ^https://([a-z0-9-]+\.)*editor\.polyglots\.social$
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=os.getenv("EDITOR_ALLOWED_ORIGINS", r"^http://(localhost|127\.0\.0\.1)(:\d+)?$"),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

from routers import (
    course, exercise,
    lesson, module, video, 
    prompt, task_status,
    context, languages, words, ai_keys, auth,
)



# Everything but signing in needs a signed-in editor.
app.include_router(auth.router, prefix="/api/v1/auth", tags=["auth"])
_signed_in = [Depends(get_school_user)]
app.include_router(course.router, prefix="/api/v1/courses", dependencies=_signed_in, tags=["courses"])
app.include_router(exercise.router, prefix="/api/v1/exercises", dependencies=_signed_in, tags=["exercises"])
app.include_router(lesson.router, prefix="/api/v1/lessons", dependencies=_signed_in, tags=["lessons"])
app.include_router(module.router, prefix="/api/v1/modules", dependencies=_signed_in, tags=["modules"])
app.include_router(video.router, prefix="/api/v1/video", dependencies=_signed_in, tags=["video"])
app.include_router(prompt.router, prefix="/api/v1/prompt", dependencies=_signed_in, tags=["prompt"])
app.include_router(task_status.router, prefix="/api/v1/tasks", dependencies=_signed_in, tags=["tasks"])
app.include_router(context.router, prefix="/api/v1/context", dependencies=_signed_in, tags=["context"])
app.include_router(languages.router, prefix="/api/v1/language", dependencies=_signed_in, tags=["language"])
app.include_router(words.router, prefix="/api/v1/words", dependencies=_signed_in, tags=["words"])
app.include_router(ai_keys.router, prefix="/api/v1/ai", dependencies=_signed_in, tags=["ai"])
