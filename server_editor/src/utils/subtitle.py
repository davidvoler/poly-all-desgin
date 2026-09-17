

async def get_subtitles(video_id: str) -> list:
    # Implement your logic to fetch subtitles for the given video_id
    return []

async def break_subtitles_phrases(subtitles: list) -> list:
    return []

async def break_subtitles_words(subtitles: list) -> list:
    return []

async def break_subtitles_sentences(subtitles: list) -> list:
    return []


def break_subtitles_into_sections(lines: list, break_video_seconds: float = 120.0) -> list:
    next_break = break_video_seconds
    text = ""
    sections = []
    last_break = 0
    for l in lines:
        start = float(l.get("start", 0))
        duration = float(l.get("duration ", 0))
        if start > next_break:
            text += l.get("text", "") # adding text to the current break - even if it is also added to the beginning of the next break
            sections.append({"text": text , "start": last_break, "end": start+duration})
            next_break += break_video_seconds
            last_break = next_break
            text = l.get("text", "") + " "
        else:
            text += l.get("text", "") + " "
    sections.append({"text": text , "start": last_break, "end": start+duration})
    return sections

