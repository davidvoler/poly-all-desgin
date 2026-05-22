from pydantic import BaseModel
from datetime import datetime as DateTime

class UserCourseProgress(BaseModel):
    user_id: int
    course_id: int
    progress: int| None = 0
    current_module: int = 1
    current_lesson: int = 1

class Lesson(BaseModel):
    lesson_id: int 
    title: str| None = ''
    description: str | None = ''
    words: list[str] | None = []
    completed: int | None = 0

class Module(BaseModel):
    module_id: int 
    title: str| None = ''
    description: str | None = ''
    words: list[str] | None = []
    completed: int | None = 0

class Course(BaseModel):
    course_id: int 
    title: str| None = ''
    description: str | None = ''
    lang: str
    to_lang: str 
    tags : list[str] | None = []
    lesson_count: int | None = 0
    user_lessons_done: int | None = 0
    avg_score: float | None = 0.0
    progress: int | None = 0
    current_module: int | None = 1
    current_lesson: int | None = 1



class Exercise(BaseModel):
    exercise_id: int
    sentence: str | None = ''
    exercise_type: str | None = ''
    options: list | None = []
    audio: str | None = ''
    word1: str | None = ''
    word2: str | None = ''
    word3: str | None = ''
    sentence_id: int |  None = None
    to_sentence_id: int | None = None


class Word(BaseModel):
    word: str
    last_practiced: DateTime | None = None
    score: float | None = None


class SelectedWords(BaseModel):
    user_id: int
    lang: str
    words: list[str] = []


class LessonCompleted(BaseModel):
    user_id: int
    lang: str| None = ''
    course_id: int = 0
    module_id: int = 0
    lesson_id: int
    score: float = 0.0
    skipped_count: int = 0
    correct_count: int = 0
    wrong_count: int = 0
    course_lessons_count: int = 0


class PracticeCompleted(BaseModel):
    user_id: int
    lang: str| None = ''
    course_id: int = 0
    score: float = 0.0
    skipped_count: int = 0
    correct_count: int = 0
    wrong_count: int = 0
    words_count: int = 0
    course_lessons_count: int = 0




class CourseStatus(BaseModel):
    course_id: int
    progress: int 
    lessons_completed: int
    total_lessons: int
    module_completed: int
    total_modules: int
    