from pydantic import BaseModel


class WordRank(BaseModel):
    word: str
    rank: int
    number_of_occurrences: int = 1 

class SubtitleLine(BaseModel):
    start: float= 0
    duration: float = 0
    end: float = 0
    text: str = ''

class VideoSection(BaseModel):
    start_seconds: float
    end_seconds: float
    subs: list[SubtitleLine] | None = []
    words: list[WordRank] | None = []
    sentences: list[str] | None = []
    parts: list[str] | None = []


class VideoParts(BaseModel):
    video_id: str
    part_id: int 
    start_seconds: float =0
    end_seconds: float =0
    full_text: str  =  ''
    all_words: list[WordRank] | None = []
    sections: list[VideoSection] | None = []



