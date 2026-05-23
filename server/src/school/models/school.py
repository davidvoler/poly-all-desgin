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


class ActivityRow(BaseModel):
    """One row in the Overview "Recent activity" feed. The dashboard
    renders `kind` as a colored dot (course_upload / editor_invite /
    generic) and shows the actor's name on its own line above `summary`."""
    activity_id: int
    school_id: int
    actor_user_id: int | None = None
    actor_name: str = ''
    kind: str
    summary: str
    created_at: DateTime | None = None
    when_human: str = ''       # pre-rendered "2 h ago"-style relative timestamp


class LanguageSummary(BaseModel):
    """Per-language aggregate shown on the Languages page. The dashboard
    splits these into "we teach" (`role='teach'`) vs. "students speak"
    (`role='native'`) — same shape, different source list."""
    lang: str
    role: str                  # 'teach' | 'native'
    flag: str = ''
    native: str = ''
    english: str = ''
    rtl: bool = False
    courses: int | None = None
    students: int = 0
    percent_of_school: str | None = None
    active: bool = True


class StudentRow(BaseModel):
    """Roster row on the Students page. Joins user_data.users with
    school.student_enrollments to give the dashboard everything it
    needs to render the table in one round-trip."""
    user_id: int
    name: str = ''
    email: str = ''
    lang: str = ''
    lang_flag: str = ''
    lang_name: str = ''
    course: str = ''            # human label, "A1 Foundations · Module 4"
    course_id: int | None = None
    progress: float = 0.0
    last_seen: DateTime | None = None
    last_seen_human: str = 'Never'
    status: str = 'active'      # active | slowing | inactive | no_course
