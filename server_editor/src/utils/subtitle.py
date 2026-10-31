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
    next_break = break_video_seconds
    text = ""
    sections = []
    last_break = 0
    for l in lines:
        start = float(l.start)
        duration = float(l.duration)
        if start > next_break:
            text += l.text # adding text to the current break - even if it is also added to the beginning of the next break
            end = start + duration +0.5
            sections.append(VideoSection(text=text , start=last_break, end=end))
            next_break +=  start + duration
            last_break = next_break
            text = l.text + " "
        else:
            text += l.text + " "
    sections.append(VideoSection(text=text , start=last_break, end=start+duration))
    return sections

