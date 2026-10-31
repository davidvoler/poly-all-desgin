from utils.edit.youtube_srt import youtube_subs

video_id = "https://www.youtube.com/watch?v=-0BEGR1uejs"
video_id = "-0BEGR1uejs"
lang = "ar"
subs = youtube_subs(video_id, lang)
# print(subs)
# print(type(subs))
section_length = 120
with open(f"{video_id}_{lang}.srt", "w", encoding="utf-8") as f:
    text = ""
    for line in subs[0]:
        print(line)
        f.write(f"{line.get('start')} -> {line.get('duration')}\n")
        # text = test + line.get('text') + " "
        f.write(f"{line.get('text')}\n")
    # sentences = text.split(". ")
    
