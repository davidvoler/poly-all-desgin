from enum import Enum
from pydantic import BaseModel

class Stages(Enum, str):
    COURSE = "course" # course generation - general information about the course 
    MODULE = "module" # module generation - we have started a new module - We need words for this module 
    LESSON = "lesson"
    WORDS = "words"
    VIDEO = "video" # We are using an existing video 




class AgentState(Enum, str):
    IDLE = "idle"
    PROCESSING = "processing"
    COMPLETED = "completed"
    ERROR = "error"