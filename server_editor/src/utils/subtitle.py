from urllib.parse import parse_qs, urlparse

from youtube_transcript_api import YouTubeTranscriptApi
from youtube_transcript_api._transcripts import FetchedTranscript
from youtube_transcript_api._transcripts import FetchedTranscriptSnippet
from models.video import Subtitle, VideoSection

ytt_api = YouTubeTranscriptApi()

_PATH_ID_PREFIXES = ('/shorts/', '/embed/', '/live/', '/v/')


def youtube_id_from_url(url: str) -> str | None:
    """Pull the video id out of any common YouTube URL shape:
    youtu.be/<id>, youtube.com/watch?v=<id>, /shorts/<id>, /embed/<id>,
    /live/<id>, /v/<id> — with or without a scheme."""
    url = url.strip()
    if url and '//' not in url:
        url = f'https://{url}'
    try:
        parsed = urlparse(url)
    except ValueError:
        return None
    host = (parsed.hostname or '').lower()
    if not host:
        return None
    if 'youtu.be' in host:
        video_id = parsed.path.strip('/').split('/')[0]
        return video_id or None
    if 'youtube.com' in host:
        video_id = parse_qs(parsed.query).get('v')
        if video_id and video_id[0]:
            return video_id[0]
        for prefix in _PATH_ID_PREFIXES:
            if parsed.path.startswith(prefix):
                video_id = parsed.path[len(prefix):].strip('/').split('/')[0]
                return video_id or None
    return None



def youtube_subs(video_id: str, lang: str) -> list[Subtitle]:
    """Fetch subtitles for a given YouTube video ID and language."""
    ts = ytt_api.fetch(video_id, languages=[lang])
    video_seconds = 0
    subs = []
    for t in ts:
        subs.append(Subtitle(
            start=t.start,
            duration=t.duration,
            text=t.text
        ))
        video_seconds = max(video_seconds, t.start + t.duration)
    return subs

def break_subtitles_into_sections(lines: list[Subtitle], break_video_seconds: float = 120.0) -> list[VideoSection]:
    """Groups subtitles into consecutive sections of about break_video_seconds each.
    A section ends at a subtitle boundary, so no line is cut or repeated."""
    sections: list[VideoSection] = []
    current: list[Subtitle] = []
    for line in lines:
        if current and line.start >= current[0].start + break_video_seconds:
            sections.append(_section(current))
            current = []
        current.append(line)
    if current:
        sections.append(_section(current))
    return sections


def _section(lines: list[Subtitle]) -> VideoSection:
    start = lines[0].start
    end = max(l.start + l.duration for l in lines)
    return VideoSection(start=start, end=end, duration=end - start,
                        text=" ".join(l.text.replace("\n", " ").strip() for l in lines))
