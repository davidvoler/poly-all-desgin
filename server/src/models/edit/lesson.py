from pydantic import BaseModel


class LessonEdit(BaseModel):
    course_id: int| None = 0
    module_id: int| None = 0
    lesson_id: int | None = 0
    title: str | None = ''
    description: str | None = ''
    words: list[str] | None = []
    status: str | None = 'draft'


# --- Create-with-AI copilot additions (see TASKS.md "Planning the api") --
# All POST, ids passed in the body — no path parameters, per the
# "API Manual planning" convention.

class LessonWordsRequest(BaseModel):
    lesson_id: int
    words: list[str]


class LessonSentence(BaseModel):
    sentence_id: int
    lesson_id: int
    word: str | None = None
    text: str
    gloss: str | None = ''
    chosen: bool = True


class SentencesConfirmRequest(BaseModel):
    lesson_id: int
    sentence_ids: list[int]


class SentenceUpdateRequest(BaseModel):
    lesson_id: int
    sentence_id: int
    text: str


class SentenceDeleteRequest(BaseModel):
    lesson_id: int
    sentence_id: int
