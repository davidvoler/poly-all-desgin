from youtube_transcript_api import YouTubeTranscriptApi
from youtube_transcript_api._transcripts import FetchedTranscript
from youtube_transcript_api._transcripts import FetchedTranscriptSnippet

BASE_FOLDER = '../data/content/srt'
ytt_api = YouTubeTranscriptApi()

def youtube_to_srt(video_id: str, lang: str):
    ts = ytt_api.fetch(video_id, languages=[lang])
    srt_file = f"{BASE_FOLDER}/{video_id}_{lang}.srt"
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

if __name__ == "__main__":
    subs, video_seconds = youtube_subs('1LV0pU2U_hg', 'el')
    print(subs)
    print(f"Video duration: {int(video_seconds/60)}:{int(video_seconds%60)} minutes")