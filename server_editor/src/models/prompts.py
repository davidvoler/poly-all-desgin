from pydantic import BaseModel, Field
from enum import Enum
from models.course import Course
from models.module import Module
from models.word import Word

class PromptResultsType(Enum):
    OPTION = "option" # show the options 
    NEW_COURSE = "new_course"
    NEW_MODULE = "new_module"
    TASK_ID = "task_id" # show spinner and reload current module when spinner completes

# indicating which router took care of the prompt request
class PromptRouterType(Enum):
    COURSE = "course"
    MODULE = "module"
    LESSON = "lesson"
    VOCABULARY = "vocabulary"
    EXERCISE = "exercise"
    VIDEO = "video"
    MAIN = "main"
    UNKNOWN = "unknown"

class PromptActionType(Enum):
    OPTIONS = "options"
    ASK_AI = "ask_ai"
    CACHE = "cache"
    SIMPLE = "simple"


class PromptType(Enum):
    EXERCISE_MULTIPLE_CHOICE = "multiple_choice"
    EXERCISE_FILL_IN_THE_BLANK = "fill_in_the_blank"
    EXERCISE_TRUE_FALSE = "true_false"
    EXERCISE_SINGLE_CHOICE = "single_choice"
    EXERCISE_EXPLANATION = "explanation"
    LESSON_CREATE = "create_lesson"
    COURSE_CREATE = "create_course"
    COURSE_ATTRIBUTE = "course_attribute"
    MODULE_CREATE = "create_module"
    MODULE_ATTRIBUTE = "module_attribute"
    MODULE_CREATE_SUGGEST_WORDS = "create_module_suggest_words"
    VIDEO_SECTIONS = "video_sections"
    VIDEO_PARTS = "video_parts"
    VIDEO_MODULE = "video_module"  # start a module from a video URL
    VIDEO_EXTRACT = "video_extract"  # extract words and sentences from the next part
    VIDEO_EXTRACT_AND_EXERCISES = "video_extract_and_exercises"  # the same, then exercises from them
    VIDEO_WORD_EXERCISES = "video_word_exercises"  # a part's words -> single choice, no AI
    VIDEO_SENTENCE_EXERCISES = "video_sentence_exercises"  # a part's sentences -> single choice, random wrong options
    VIDEO_SENTENCE_EXERCISES_AI = "video_sentence_exercises_ai"  # the same, with AI-written wrong options
    VOCABULARY_SUGGEST_WORDS = "vocabulary_suggest_words"


class PromptOptionData(BaseModel):
    label: str = Field(..., description="The label of the prompt option.")
    field_name: str = Field(..., description="The name of the field associated with the prompt option.")
    value: str|None = Field(..., description="The value associated with the prompt option.")

class PromptRequest(BaseModel):
    course_id: int|None = Field(0, description="The ID of the course in the context.")
    module_id: int|None = Field(0, description="The ID of the module in the context.")
    lesson_id: int|None = Field(0, description="The ID of the lesson in the context.")
    exercise_count: int|None = Field(0, description="The count of exercises in the context.")
    user_message: str = Field('', description="The message input from the user.") 
    provider: str = Field('ollama', description="The AI provider associated with the prompt request.")
    model: str = Field('gemma4', description="The model to use for the prompt request.")
    prompt_values: list|None = Field([], description="Values for the prompts could be words, sentences, or other relevant data.")
    router_type: PromptRouterType|None = Field(None, description="The type of prompt router associated with the prompt request.")
    prompt_type: PromptType|None = Field(None, description="The type of action associated with the last prompt request.")
    last_router_type: PromptRouterType|None = Field(None, description="The type of prompt router associated with the prompt request.")
    last_prompt_type: PromptType|None = Field(None, description="The type of action associated with the last prompt request.")
    comment: str|None = Field('', description="Additional comments associated with the prompt request.")
    words: list[Word]|None = Field([], description="The list of words associated with the prompt request.")
    is_option: bool = Field(False, description="Indicates whether this is an option.")




class PromptOption(PromptRequest):
    is_option: bool = Field(False, description="Indicates whether this is an option.")
    option_text: str = Field("", description="The text of the option.")
    option_data: list[PromptOptionData]|None = Field(None, description="The data associated with the prompt option.")

class PromptResponse(BaseModel):
    request_user_message: str = Field('', description="The message input from the user in the original request.")
    course_id: int|None = Field(0, description="The ID of the course in the context.")
    module_id: int|None = Field(0, description="The ID of the module in the context.")
    lesson_id: int|None = Field(0, description="The ID of the lesson in the context.")
    option: list[PromptOption]|None = Field(None, description="The option associated with this response, if applicable.")
    task_id: str|None = Field('', description="The ID of the task associated with this response, if applicable.")
    results: dict|None = Field({}, description="The results associated with this response, if applicable.")
    results_type: str|None = Field('dict', description="The type of the results associated with this response, if applicable.")
    ui_chat_response: dict|None = Field({}, description="The UI chat response associated with this response, if applicable.")
    prompt_router_type: PromptRouterType|None = Field(None, description="The type of prompt router associated with this response, if applicable.")
    prompt_type: PromptType|None = Field(None, description="The type of prompt associated with this response, if applicable.")
    prompt_action_type: PromptActionType|None = Field(None, description="The type of action associated with this response, if applicable.")
    is_option: bool|None = Field(None, description="Indicates whether this response is an option.")

