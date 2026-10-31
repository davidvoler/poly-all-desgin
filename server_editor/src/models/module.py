from pydantic import BaseModel, Field
from models.lesson import LessonFull

class ModuleOption(BaseModel):
    max_words_in_sentences: int|None = Field(..., description="The maximum number of words allowed in sentences for the module.")
    transliteration: bool|None = Field(..., description="Indicates whether transliteration is enabled for the module.")
    transliteration_format: str|None = Field(..., description="The format used for transliteration in the module.")
    number_of_exercises_per_word: int|None = Field(..., description="The number of exercises to create per word for the module.")
    exercise_type_single_choice: bool|None = Field(..., description="Indicates whether the exercise type is single choice for the module.")
    exercise_type_multiple_choice: bool|None = Field(..., description="Indicates whether the exercise type is multiple choice for the module.")
    exercise_type_fill_in_the_blank: bool|None = Field(..., description="Indicates whether the exercise type is fill in the blank for the module.")
    exercise_type_true_false: bool|None = Field(..., description="Indicates whether the exercise type is true/false for the module.")
    exercise_type_matching: bool|None = Field(..., description="Indicates whether the exercise type is matching for the module.")
    exercise_type_explanation: bool|None = Field(..., description="Indicates whether the exercise type is explanation for the module.")

class Module(BaseModel):
    course_id: int|None = None
    module_id: int|None = None
    module_type: str|None = None
    title: str|None = None
    description: str|None = None
    deleted: bool|None = False
    weight: int|None = 0
    module_options: ModuleOption|None = None
    #edit related content - we could remove it from the student version - when publishing
    words: list[str]|None = None
    sentences: list[str]|None = None
    phrases: list[str]|None = None
    #video fields applicable for lessons of type video
    video_url: str|None = None
    subtitles: list[str]|None = None


class ModuleFull(Module):
    module: Module|None = None
    lessons: list[LessonFull]|None = None