from pydantic import BaseModel
from enum import Enum

from server.src.models.edit.generate_params import CorpusNames
from server.src.routers.edit import word
class ContentSource(str, Enum):
    AI = "ai"
    CORPUS = "corpus"
class AiProvider(str, Enum):
    OLLAMA = "ollama"
    OPENAI = "openai"
    CLAUDE = "claude"
class AiModel(str, Enum):
    GEMMA4 = "gemma4"


class CourseParams(BaseModel):
    title: str | None = ''
    description: str | None = ''
    value: str | None = ''

class CourseWord(BaseModel):
    word: str  = ''
    weight: int  = 0
    used: int  = 0


class CourseOption(BaseModel):
    coutent_source: ContentSource | None = ContentSource.CORPUS
    model: AiModel | None = AiModel.GEMMA4
    # sentence and exercise generate
    max_sentences_words: int | None = 4
    min_sentences_words: int | None = 1
    distractor_similarity: float | None = 0.5
    single_choice: float | None = 0.9
    multiple_choice: float | None = 0.1
    identify_words: float | None = 0.1
    description: float | None = 0.0


class Course(BaseModel):
    course_id: int
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
