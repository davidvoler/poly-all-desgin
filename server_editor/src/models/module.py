from pydantic import BaseModel

class Module(BaseModel):
    course_id: int|None = None
    module_id: int|None = None
    module_type: str|None = None
    title: str|None = None
    description: str|None = None
    deleted: bool|None = False
    weight: int|None = 0
    #edit related content - we could remove it from the student version - when publishing
    words: list[str]|None = None
    sentences: list[str]|None = None
    phrases: list[str]|None = None
    #video fields applicable for lessons of type video
    video_url: str|None = None
    subtitles: list[str]|None = None
