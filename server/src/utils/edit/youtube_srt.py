from youtube_transcript_api import YouTubeTranscriptApi
from youtube_transcript_api._transcripts import FetchedTranscript
from youtube_transcript_api._transcripts import FetchedTranscriptSnippet

BASE_FOLDER = '../data/content/srt'
ytt_api = YouTubeTranscriptApi()

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
    subs = []
    for t in ts:
        subs.append({
            "start": t.start,
            "duration": t.duration,
            "text": t.text
        })
    return subs

if __name__ == "__main__":
    youtube_to_srt('1LV0pU2U_hg', 'el')