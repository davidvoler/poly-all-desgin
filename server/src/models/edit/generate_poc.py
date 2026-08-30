from modulefinder import Module

from pydantic import BaseModel
from enum import Enum

from models.edit.ai_course import CourseWord, ExerciseOut, LessonSentenceOut

class PromptType(str, Enum):
    CREATE_LESSON = "create_lesson"
    GET_WORDS = "get_words"
    CREATE_COURSE = "create_course"
    CREATE_MODULES = "create_modules"


class Prompt(BaseModel):
    provider: str|None = None
    model: str|None = None
    lang: str|None = None
    course_id: int|None = None
    module_id: int|None = None
    to_lang: str|None = None
    prompt: str|None = None
    prompt_type: PromptType|None = None
    extra_data: dict|None = None
    token_estimate: int|None = None
    estimated_cost: float|None = None

class GenerateCourseRequest(Prompt):
    prompt_type: PromptType | None = PromptType.CREATE_COURSE
    title: str | None = ''
    description: str | None = ''
    level: str | None = 'A1'

class GenerateLessonRequest(Prompt):
    prompt_type: PromptType | None = PromptType.CREATE_LESSON
    title: str | None = ''
    course_id: int | None = None
    module_id: int | None = None
    lesson_id: int | None = None
    words: list[str] | None = []

class GenerateWordsRequest(Prompt):
    prompt_type: PromptType | None = PromptType.GET_WORDS
    course_id: int | None = None
    count: int | None = 300

class GenerateSentencesRequest(Prompt):
    prompt_type: PromptType | None = PromptType.CREATE_LESSON
    lesson_id: int | None = None

class GenerateExercisesRequest(Prompt):
    prompt_type: PromptType | None = PromptType.CREATE_LESSON
    lesson_id: int | None = None



# Responses
class PromptResponseOption(BaseModel):
    title: str | None = ''
    text: str | None = ''
    prompt_type: PromptType


class PromptResponse(BaseModel):
    prompt_type: PromptType | None = None
    prompt: str | None = ''
    title: str | None = ''
    description: str | None = ''
    options: list[PromptResponseOption] | None = []
    response: str | None = ''
    course_id: int | None = None
    lang: str | None = None
    to_lang: str | None = None
    actual_cost: float | None = 0.0
    actual_tokens: int | None = 0


class GenerateWordsResponse(PromptResponse):
    words: list[CourseWord] = []


class GenerateSentencesResponse(PromptResponse):
    sentences: list[LessonSentenceOut] = []


class GenerateExercisesResponse(PromptResponse):
    exercises: list[ExerciseOut] = []


class GenerateLessonResponse(PromptResponse):
    sentences: list[LessonSentenceOut] = []
    exercises: list[ExerciseOut] = []



class Course(BaseModel):
    course_id: int | None = None
    lang: str | None = None
    to_lang: str | None = None
    title: str | None = ''
    description: str | None = ''
    level: str | None = 'A1'
    words: list[CourseWord] | None = []
    modules: list[Module] | None = []