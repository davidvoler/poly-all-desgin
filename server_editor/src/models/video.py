from pydantic import BaseModel

class VideoRequest(BaseModel):
    pass

class Video(BaseModel):
    video_id: int
    lang: str
    to_lang: str
    user: int
    school: int
    deleted: bool
    subtitle: str | None = None


class Subtitle(BaseModel):
    start: float = 0.0
    duration: float = 0.0
    text: str = ""



class VideoSection(BaseModel):
    start: float = 0.0
    end: float = 0.0
    duration: float = 0.0
    text: str = ""


class VideoElement(BaseModel):
    start: float = 0.0
    end: float = 0.0
    duration: float = 0.0
    text: str = ""
    words: list[str] = []
    sentences: list[str] = []
    phrases: list[str] = []
    clauses: list[str] = []
