from pydantic import BaseModel
from datetime import datetime as DateTime


class School(BaseModel):
    """One row in `school.schools` — the tenant the dashboard is scoped to."""
    school_id: int | None = None
    slug: str
    name: str
    plan: str = 'free'                       # free | pro | enterprise
    school_type: str = 'private'             # public | no_charge | private
    is_public: bool = False                  # legacy alias for school_type='public'
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
    school_type: str = 'private'             # public | no_charge | private
    # Legacy flag — when set without an explicit school_type we map to
    # 'public'. New callers should send school_type directly.
    is_public: bool = False
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


class PlanFeature(BaseModel):
    """One row in `school.plan_features` — a feature label + an
    `included` flag that drives the green check / grey dash on the
    Settings → Subscription plans cards."""
    label: str
    included: bool = True
    weight: int = 0


class Plan(BaseModel):
    """One row in `school.plans` with its features inlined so the
    Settings page can render an entire plan card from a single GET."""
    plan_id: int | None = None
    school_id: int
    tier: str
    price_cents: int = 0
    cadence: str = 'monthly'        # monthly | yearly
    blurb: str | None = None
    featured: bool = False
    weight: int = 0
    features: list[PlanFeature] = []
    subscriber_count: int = 0       # COUNT(DISTINCT user_id) from enrollments


class PlanWrite(BaseModel):
    """Write-side shape for POST/PUT — no plan_id and no school_id (the
    latter comes from the URL). Features are sent inline so the editor
    can rearrange the checklist atomically."""
    tier: str
    price_cents: int = 0
    cadence: str = 'monthly'
    blurb: str | None = None
    featured: bool = False
    weight: int = 0
    features: list[PlanFeature] = []


class BillingMethod(BaseModel):
    """One row in `school.billing_methods`. Only the primary card is
    surfaced on the dashboard for now; the table supports additional
    rows so a second-card flow is a one-field UI change later."""
    billing_method_id: int | None = None
    school_id: int
    brand: str = 'Card'
    last4: str
    exp_month: int
    exp_year: int
    is_primary: bool = True


class BillingMethodWrite(BaseModel):
    brand: str = 'Card'
    last4: str
    exp_month: int
    exp_year: int


class EnrollStudentRequest(BaseModel):
    """Payload for POST /api/v1/school/{id}/students — single-student
    enrollment from the Students-page dialog. `course_id` is optional;
    when omitted the student lands in the "no course yet" bucket and
    the dashboard surfaces them under that filter chip."""
    email: str
    name: str = ''
    lang: str
    course_id: int | None = None
    cohort: str | None = None


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
