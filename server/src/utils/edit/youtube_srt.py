from urllib.parse import parse_qs, urlparse

from youtube_transcript_api import YouTubeTranscriptApi
from youtube_transcript_api._transcripts import FetchedTranscript
from youtube_transcript_api._transcripts import FetchedTranscriptSnippet
from models.edit.youtube import YoutubeParts


BASE_FOLDER = '../data/content/srt'
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

def youtube_to_srt(video_id: str, lang: str, base_folder: str = BASE_FOLDER) -> str:
    ts = ytt_api.fetch(video_id, languages=[lang])
    srt_file = f"{base_folder}/{video_id}_{lang}.srt"
    i = 1
    with open(srt_file, 'w') as f:
        for t in ts:
            f.write(f"{i}\n")
            f.write(f"{t.start} --> {t.start + t.duration}\n")
            f.write(f"{t.text}\n")
            f.write("\n")
            i += 1
    return srt_file


def youtube_subs(video_id: str, lang: str) -> list:
    ts = ytt_api.fetch(video_id, languages=[lang])
    video_seconds = 0
    subs = []
    for t in ts:
        subs.append({
            "start": t.start,
            "duration": t.duration,
            "text": t.text
        })
        video_seconds = max(video_seconds, t.start + t.duration)
    return subs, video_seconds


def subs_parts(video_id: str, subs: list[dict], video_seconds: int, number_of_parts: int = 10) -> list[YoutubeParts]:
    """
    Split the subtitles into parts based on the number of parts and minimum part duration.
    """
    part_duration = video_seconds / number_of_parts
    parts = []
    current_part = 1
    current_subs = []
    for s in subs:
        if s['start'] < current_part * part_duration:
            current_subs.append(s)
        else:
            parts.append(
                YoutubeParts(
                video_id=video_id,
                part_id=current_part,
                start_seconds=current_subs[0]['start'] if current_subs else 0,
                end_seconds=current_subs[-1]['start'] + current_subs[-1]['duration'] if current_subs else 0,
                subs=current_subs,
                words=[],
                sentences=[])
            )
            current_part += 1
            current_subs = [s]
    if len(current_subs) > 0:
        parts.append(
            YoutubeParts(
            video_id=video_id,
            part_id=current_part+1,
            start_seconds=current_subs[0]['start'] if current_subs else 0,
            end_seconds=current_subs[-1]['start'] + current_subs[-1]['duration'] if current_subs else 0,
            subs=current_subs,
            words=[],
            sentences=[])
        )
    return parts

if __name__ == "__main__":
    youtube_to_srt('1LV0pU2U_hg', 'el')