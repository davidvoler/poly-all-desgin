"""
Part utils module.
"""
from pydantic import BaseModel
from wordfreq import zipf_frequency
MIN_RANK=400
MAX_RANK=800

def get_ranked_words(words:list,lang, min_rank=MIN_RANK, max_rank=MAX_RANK) -> list[dict]:
    ranked = []
    words = list(set(words))
    for w in words:
        r = 1000 - int(zipf_frequency(w,lang) * 100)
        if r <= max_rank and r > min_rank:
            ranked.append({"word": w, "rank": r})
    return ranked

def text_to_parts(text: str) -> list[str]:
    sentences = text.split('.')
    sentences = list(set([s.strip() + '.' for s in sentences if s.strip()]))
    parts = []
    for s in sentences:
       phrases = s.split(',')
       for p in phrases:
           if p.strip():
               parts.append(p.strip())
    parts = list(set(parts))
    return sentences, parts





def srt_to_text(srt_file: str) -> str:
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
    return full_text.strip()

def break_srt(srt_file: str, second_count = 300) -> list[str]:
    text_parts = []
    full_text = ''
    first_time = -1
    next_time = second_count
    with open(srt_file, 'r') as f:
        lines = f.readlines()
        for i in range(0, len(lines), 4):
            start_time = float(lines[i + 1].split(' --> ')[0])
            if first_time == -1:
                first_time = start_time
            text = lines[i + 2].strip()
            if start_time > next_time:
                sentences_parts = text.split('.')
                added_text = ''
                if len(sentences_parts) > 1:
                    added_text = sentences_parts[0] + '.'

                text_parts.append({
                    "start": first_time,
                    "end": start_time,
                    "text": full_text.strip() + ' ' + added_text.strip()
                })
                first_time = start_time
                next_time += second_count
                if added_text:
                    full_text = '.'.join(sentences_parts[1:]).strip() + ' '
                else:
                    full_text = text + ' '
            else:
                full_text += text.strip() + ' '
    if full_text:
        text_parts.append({
            "start": first_time,
            "last_time": start_time,
            "text": full_text.strip()
        })
    return text_parts




   