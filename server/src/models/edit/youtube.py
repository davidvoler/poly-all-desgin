from pydantic import BaseModel


class SubtitleLine(BaseModel):
    start: float= 0
    end: float = 0
    text: str = ''


class YoutubeInfo(BaseModel):
    video_id: str
    title: str | None = ''
    subtitles_langs: list[str] | None = []
    video_lang: str | None = ''
    length: int | None = 0
    auto_generated: bool | None = False


class SubtitlesDownloadRequest(BaseModel):
    video_id: str
    lang: str


class SubtitleInfo(BaseModel):
    video_id: str
    title: str | None = ''
    video_lang: str | None = ''
    lines: list[SubtitleLine] | None = []
    sentences: list[str] | None = []
    words: list[str] | None = []
    