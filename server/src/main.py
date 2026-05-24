import os

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from routers import (
    auth,
    lesson,
    course,
    module,
    exercise,
    user_data,
    preference,
    user_stats,
    practice,
    achievement
)
from school.routes import school as school_routes, users as school_users
from editor.routes import (
    upload_course,
    export_course,
    editor_courses,
    review as editor_review,
    lesson as editor_lesson,
)

app = FastAPI()

# CORS — credentialed requests (i.e. every /api/v1/auth/* call, which
# carries the HttpOnly user_id cookie) require an explicit origin
# list. Browsers reject `*` + `allow_credentials=True` per the CORS
# spec, which is what produced the
# "No 'Access-Control-Allow-Origin' header is present" failure from
# app.polyglots.social hitting api.polyglots.social.
#
# Configure via the CORS_ORIGINS env (comma-separated) on the prod
# box; the default list covers a local docker-compose stack so a
# fresh checkout still works without env setup.
_DEFAULT_CORS_ORIGINS = (
    "http://localhost:3000,"
    "http://127.0.0.1:3000,"
    "http://localhost:5000,"
    "http://127.0.0.1:5000,"
    "http://localhost:8000,"
    "http://127.0.0.1:8000,"
    "https://www.polyglots.social,"
    "https://app.polyglots.social,"
    "https://dashboard.polyglots.social"
)
_cors_origins = [
    o.strip() for o in os.getenv("CORS_ORIGINS", _DEFAULT_CORS_ORIGINS).split(",")
    if o.strip()
]
# `flutter run -d chrome` picks a random ephemeral port (62889 today,
# something else tomorrow). The regex below matches any localhost /
# 127.0.0.1 port so dev keeps working without re-listing it every
# time. Production scope is unchanged — the regex can't widen prod
# since the allowed hosts are still just localhost.
_cors_origin_regex = os.getenv(
    "CORS_ORIGIN_REGEX",
    r"https?://(localhost|127\.0\.0\.1)(:\d+)?$",
)
app.add_middleware(
    CORSMiddleware,
    allow_origins=_cors_origins,
    allow_origin_regex=_cors_origin_regex,
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
app.include_router(module.router,
    prefix="/api/v1/module",
    tags=["module"])
app.include_router(exercise.router,
    prefix="/api/v1/exercise",
    tags=["exercise"])
app.include_router(preference.router,
    prefix="/api/v1/preference",
    tags=["preference"])
app.include_router(user_stats.router,
    prefix="/api/v1/user_stats",
    tags=["user_stats"])
app.include_router(practice.router,
    prefix="/api/v1/practice",
    tags=["practice"])
app.include_router(achievement.router,
    prefix="/api/v1/achievement",
    tags=["achievement"])
app.include_router(auth.router,
    prefix="/api/v1/auth",
    tags=["auth"])

# --- School-admin dashboard ---------------------------------------------------
app.include_router(school_routes.router,
    prefix="/api/v1/school",
    tags=["school"])
app.include_router(school_users.router,
    prefix="/api/v1/school_users",
    tags=["school_users"])

# --- Course editor (dashboard-side, not the public app) -----------------------
app.include_router(upload_course.router,
    prefix="/api/v1/editor/upload",
    tags=["editor_upload"])
app.include_router(export_course.router,
    prefix="/api/v1/editor/export",
    tags=["editor_export"])
app.include_router(editor_courses.router,
    prefix="/api/v1/editor/courses",
    tags=["editor_courses"])
app.include_router(editor_review.router,
    prefix="/api/v1/editor/review",
    tags=["editor_review"])
app.include_router(editor_lesson.router,
    prefix="/api/v1/editor/lesson",
    tags=["editor_lesson"])