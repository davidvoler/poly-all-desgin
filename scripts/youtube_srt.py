from youtube_transcript_api import YouTubeTranscriptApi
from youtube_transcript_api._transcripts import FetchedTranscript
from youtube_transcript_api._transcripts import FetchedTranscriptSnippet

BASE_FOLDER = '../data/content/srt'
ytt_api = YouTubeTranscriptApi()

def srt_to_sentences(srt_file: str) -> list:
    sentences = []
    full_text = ''
    with open(srt_file, 'r') as f:
        lines = f.readlines()
        for i in range(0, len(lines), 4):
            start_time = lines[i + 1].split(' --> ')[0]
            text = lines[i + 2].strip()
            sentences.append({
                "start": start_time,
                "text": text
            })
            full_text += text + ' '
    return sentences, full_text.split('.')

        
    


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
    # subs, video_seconds = youtube_subs('1LV0pU2U_hg', 'el')
    # print(subs)
    # print(f"Video duration: {int(video_seconds/60)}:{int(video_seconds%60)} minutes")
    sentences, full_text_sentences = srt_to_sentences('../data/content/srt/1LV0pU2U_hg_el.srt')
    for f in full_text_sentences:
        print(len(f.split()), ":", len(f), f)
        p = f.split(",")
        if len(p) > 1:
            for pp in p:
                print("-",pp)