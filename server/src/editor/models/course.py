from pydantic import BaseModel
from datetime import datetime as DateTime


class EditorCourse(BaseModel):
    """One row in the Editors dashboard's Courses table. Joins
    course_simple.course with the per-school access overlay so the
    dashboard can render Status + Access pills in a single round-trip."""
    course_id: int
    title: str = ''
    description: str | None = ''
    lang: str
    to_lang: str
    status: str = 'draft'                  # draft | review | published | archived
    access: str | None = None              # NULL until the row is published; public | members
    lesson_count: int = 0
    module_count: int = 0
    student_count: int = 0
    updated_at: DateTime | None = None


class CourseStatusUpdate(BaseModel):
    """Payload for POST /editor/review/{course_id}/status — the dashboard
    sends the new status the editor selected (e.g. 'review' when
    submitting for approval, 'published' when an approver releases it)."""
    status: str                             # draft | review | published | archived
    note: str | None = None                 # optional reviewer comment, stored in activity_log


class EditorLesson(BaseModel):
    lesson_id: int
    title: str = ''
    description: str = ''
    words: list[str] = []
    exercise_count: int = 0


class EditorModule(BaseModel):
    module_id: int
    title: str = ''
    description: str = ''
    weight: int = 0
    lessons: list[EditorLesson] = []


class EditorCourseDetail(BaseModel):
    """Full nested structure for the course detail page — course row +
    modules + lessons + per-lesson exercise counts. The dashboard
    renders this as an expandable tree without further round-trips."""
    course_id: int
    title: str = ''
    description: str = ''
    lang: str
    to_lang: str
    status: str = 'draft'
    access: str | None = None
    lesson_count: int = 0
    module_count: int = 0
    student_count: int = 0
    updated_at: DateTime | None = None
    modules: list[EditorModule] = []


class LessonData(BaseModel):
    """Payload for the per-lesson editor route — a single lesson worth of
    exercises that the dashboard can save without re-uploading the whole
    course. `exercises` is a free-form list, validated downstream."""
    course_id: int
    module_id: int
    lesson_id: int | None = None
    title: str = ''
    words: list[str] = []
    exercises: list[dict] = []
