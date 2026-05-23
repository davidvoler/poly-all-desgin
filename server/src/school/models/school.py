from pydantic import BaseModel
from datetime import datetime as DateTime


class School(BaseModel):
    """One row in `school.schools` — the tenant the dashboard is scoped to."""
    school_id: int | None = None
    slug: str
    name: str
    plan: str = 'free'                       # free | pro | enterprise
    streak_days: int = 0
    languages_taught: list[str] = []
    native_languages: list[str] = []
    logo_url: str | None = None
    primary_color: str = '#1E88E5'
    created_at: DateTime | None = None
    updated_at: DateTime | None = None


class SchoolCreate(BaseModel):
    """Payload for POST /api/v1/school/. The owner's name/email/password
    seed the first school_users row so the school is usable immediately."""
    slug: str
    name: str
    plan: str = 'free'
    owner_name: str
    owner_email: str
    owner_password: str


class SchoolStats(BaseModel):
    """Aggregate counts for the Overview page header tiles."""
    school_id: int
    active_languages: int = 0
    courses: int = 0
    editors: int = 0
    students: int = 0
