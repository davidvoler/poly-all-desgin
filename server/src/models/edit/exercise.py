from pydantic import BaseModel
from enums import Enum
class ExerciseType(str, Enum):
    SINGLE_CHOICE = 'single_choice'
    MULTIPLE_CHOICE = 'multiple_choice'
    EXPLAIN = 'explain'
    IDENTIFY_WORDS = 'identify_words'




class ExerciseEdit(BaseModel):
    course_id: int| None = 0
    module_id: int| None = 0
    lesson_id: int| None = 0
    exercise_id: int
    exercise_type: ExerciseType | None = ExerciseType.SINGLE_CHOICE
    sentence: str | None = ''
    options: list[str] | None = []
    word1: str | None = ''
    word2: str | None = ''
    word3: str | None = ''
    sentence_alt1: str | None = ''
    sentence_alt2: str | None = ''
    sentence_alt3: str | None = ''
    ruby_text: list[str] | None = []
    annotations: list[str] | None = []
    weight: int | None = 0
    answer: str | None = None
    sentence_id: int | None = None


# --- Create-with-AI copilot additions (see TASKS.md "Planning the api") --
# All POST, ids passed in the body — no path parameters.

class ExerciseUpdateRequest(BaseModel):
    exercise_id: int
    prompt: str | None = None  # maps onto exercise.sentence — see ExerciseOut
    options: list[str] | None = None
    answer: str | None = None


class ExerciseDeleteRequest(BaseModel):
    exercise_id: int

