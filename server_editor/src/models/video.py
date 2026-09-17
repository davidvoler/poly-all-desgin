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
    