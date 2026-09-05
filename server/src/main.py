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
    achievement, 
    auth_new,
    generate_poc,
    generate_poc_new,
)
from routers.edit import  (
    edit_course,
    course_import,
    course_export,
    word as edit_word,
    module as edit_module,
    lesson as edit_lesson,
    exercise as edit_exercise,
)

from school.routes import school as school_routes, users as school_users 
# from editor.routes import (
#     upload_course,
#     editor_courses,
#     review as editor_review,
#     lesson as editor_lesson,
# )
enable_docs =  bool(os.environ.get("ENABLE_DOCS", ""))

# from arq_worker import lifespan
app = FastAPI(
    docs_url="/docs" if enable_docs else None, 
    redoc_url="/redoc" if enable_docs else None, 
    openapi_url="/openapi.json" if enable_docs else None,
    # lifespan=lifespan,
)

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
    "http://localhost:3000",
    "http://127.0.0.1:3000",
    "http://localhost:5000",
    "http://127.0.0.1:5000",
    "http://localhost:8000",
    "http://127.0.0.1:8000",
    "https://www.polyglots.social",
    "https://app.polyglots.social",
    "https://dashboard.polyglots.social",    
    "https://school1.app.polyglots.social",    
    "https://school1.dashboard.polyglots.social",    
)
# _cors_origins = [
#     o.strip() for o in os.getenv("CORS_ORIGINS", _DEFAULT_CORS_ORIGINS).split(",")
#     if o.strip()
# ]
# `flutter run -d chrome` picks a random ephemeral port (62889 today,
# something else tomorrow). The regex below matches any localhost /
# 127.0.0.1 port so dev keeps working without re-listing it every
# time. Production scope is unchanged — the regex can't widen prod
# since the allowed hosts are still just localhost.
_cors_origin_regex = os.getenv(
    "_DEFAULT_CORS_ORIGINS",
    r"https?://(localhost|127\.0\.0\.1)(:\d+)?$",
)
app.add_middleware(
    CORSMiddleware,
    allow_origins=_DEFAULT_CORS_ORIGINS,
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
app.include_router(auth_new.router,
    prefix="/api/v1/auth",
    tags=["auth_new"])

# --- School-admin dashboard ---------------------------------------------------
app.include_router(school_routes.router,
    prefix="/api/v1/school",
    tags=["school"])
app.include_router(school_users.router,
    prefix="/api/v1/school_users",
    tags=["school_users"])
#-- new editor routes for course import/export
app.include_router(edit_course.router,
    prefix="/api/v1/edit/course",
    tags=["edit_course"])   
app.include_router(course_import.router,
    prefix="/api/v1/edit/course/import",
    tags=["import_course"])
app.include_router(course_export.router,
    prefix="/api/v1/edit/course/export",
    tags=["export_course"])
app.include_router(edit_word.router,
    prefix="/api/v1/edit/word",
    tags=["edit_word"])
app.include_router(edit_module.router,
    prefix="/api/v1/edit/module",
    tags=["edit_module"])
app.include_router(edit_lesson.router,
    prefix="/api/v1/edit/lesson",
    tags=["edit_lesson"])
app.include_router(edit_exercise.router,
    prefix="/api/v1/edit/exercise",
    tags=["edit_exercise"])

app.include_router(generate_poc.router,
    prefix="/api/v1/generate_poc",
    tags=["generate_poc"])

app.include_router(generate_poc_new.router,
    prefix="/api/v1/generate_poc_new",
    tags=["generate_poc_new"])