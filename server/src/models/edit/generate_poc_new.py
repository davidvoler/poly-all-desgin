from pydantic import BaseModel
from enum import Enum

class ContentSource(str, Enum):
    AI = "ai"
    CORPUS = "corpus"
class AiProvider(str, Enum):
    OLLAMA = "ollama"
    OPENAI = "openai"
    CLAUDE = "claude"
class AiModel(str, Enum):
    GEMMA4 = "gemma4"
    MUSE_GLIMMER = "muse-glimmer"
    DEEPSEEK = "deepseek-r1:86"



class CourseParams(BaseModel):
    title: str | None = ''
    description: str | None = ''
    value: str | None = ''

class CourseWord(BaseModel):
    word: str  = ''
    weight: int  = 0
    used: int  = 0


class CourseOption(BaseModel):
    content_source: ContentSource | None = ContentSource.CORPUS
    provider: AiProvider | None = AiProvider.OLLAMA
    model: AiModel | None = AiModel.GEMMA4
    # sentence and exercise generate
    exercises_per_word: int | None = 5
    words_per_lesson: int | None = 2
    max_sentences_words: int | None = 4
    min_sentences_words: int | None = 1
    distractor_similarity: float | None = 0.5
    # exercise-type mix — relative weights, roughly summing to 1.0
    single_choice: float | None = 0.9
    multiple_choice: float | None = 0.1
    identify_words: float | None = 0.1
    description: float | None = 0.0


class Course(BaseModel):
    course_id: int | None = None
    title: str | None = ''
    description: str | None = ''
    lang: str | None = ''
    to_lang: str | None = ''
    published: bool | None = False
    level: str | None = ''
    metadata: CourseOption | None = CourseOption()
    words: list[CourseWord] | None = []

class GenerateForWords(BaseModel):
    course: Course
    words: list[str]
    num_elements: int = 12
    # When set, generated sentences / exercises are also persisted onto
    # this lesson (course_simple.lesson.sentences + course_simple.exercise)
    # so the Lessons / Preview tabs pick them up.
    lesson_id: int | None = None

class Sentences(BaseModel):
    word: str
    sentences: list[str]

class Exercise(BaseModel):
    pass

class Lesson(BaseModel):
    pass

class Sentence(BaseModel):
    sentences: str
    word: str | None = ''
    gloss: str | None = ''
    sentence_id: int | None = None
    chosen: bool | None = True



class TaskStart(BaseModel):
    task_id: str| None = None
    task_type: str | None = None
    status: str | None = None
    error: str | None = None
    completed: bool | None = False
    